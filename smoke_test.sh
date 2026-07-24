#!/usr/bin/env bash
#
# smoke_test.sh
#
# 배포 후 다음 두 가지를 확인한다.
#   1) osrm/nominatim 구동에 필요한 파일들이 존재하는지
#   2) omeye3.route.service, omeye3.redis.service 가 정상적으로 올라왔는지
#
# 서비스는 docker compose 를 실행 후 종료되는 형태(RemainAfterExit)라서
# SubState 는 "exited" 로 보이지만 ActiveState 는 "active" 여야 한다.
# 따라서 `systemctl is-active` 결과가 "active" 인지만 확인한다.

set -u

BASE_DIR="/opt/oms/omeye/omeye-hss/.docker/osrm"

# osrm/nominatim 구동에 필요한 파일들
#   - nominatim_5.1.tar                      (nominatim docker image)
#   - osrm-backend_v26.5.0-amd64-debian.tar  (osrm-backend docker image)
#   - pbf/south-korea.osm.pbf                (nominatim import 용 pbf)
REQUIRED_FILES=(
  "${BASE_DIR}/nominatim_5.1.tar"
  "${BASE_DIR}/osrm-backend_v26.5.0-amd64-debian.tar"
  "${BASE_DIR}/pbf/south-korea.osm.pbf"
)

SERVICES=(
  "omeye3.route.service"
  "omeye3.redis.service"
)

# 필요한 파일들이 모두 존재하는지 확인한다.
# 하나라도 없으면 어떤 파일이 없는지 로그로 출력하고 non-zero 를 반환한다.
check_required_files() {
  local fail=0

  for f in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$f" ]]; then
      echo "[OK]   $f exists"
    else
      echo "[FAIL] $f is missing"
      fail=1
    fi
  done

  return "$fail"
}

# 대상 서비스들이 active 상태인지 확인한다.
check_services() {
  local fail=0

  for svc in "${SERVICES[@]}"; do
    # is-active 는 active 일 때 exit 0, 아닐 때 non-zero 를 반환한다.
    # exited(active) 상태에서도 "active" 를 출력하므로 이 값만 확인하면 된다.
    local state
    state="$(systemctl is-active "$svc" 2>/dev/null)"

    if [[ "$state" == "active" ]]; then
      echo "[OK]   $svc is active"
    else
      echo "[FAIL] $svc is '$state' (expected 'active')"
      fail=1
    fi
  done

  return "$fail"
}

main() {
  local fail=0

  check_required_files || fail=1
  check_services || fail=1

  if [[ "$fail" -ne 0 ]]; then
    echo "SMOKE TEST FAILED"
    exit 1
  fi

  echo "SMOKE TEST PASSED"
  exit 0
}

# 스크립트로 직접 실행될 때만 main 을 호출한다.
# (테스트에서 `source` 로 함수만 로드할 수 있도록 분리)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
