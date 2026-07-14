#!/usr/bin/env bash
#
# smoke_test.sh
#
# omeye3.route.service, omeye3.redis.service 가 정상적으로 올라왔는지 확인한다.
# 두 서비스는 docker compose 를 실행 후 종료되는 형태(RemainAfterExit)라서
# SubState 는 "exited" 로 보이지만 ActiveState 는 "active" 여야 한다.
# 따라서 `systemctl is-active` 결과가 "active" 인지만 확인한다.

set -u

SERVICES=(
  "omeye3.route.service"
  "omeye3.redis.service"
)

fail=0

for svc in "${SERVICES[@]}"; do
  # is-active 는 active 일 때 exit 0, 아닐 때 non-zero 를 반환한다.
  # exited(active) 상태에서도 "active" 를 출력하므로 이 값만 확인하면 된다.
  state="$(systemctl is-active "$svc" 2>/dev/null)"

  if [[ "$state" == "active" ]]; then
    echo "[OK]   $svc is active"
  else
    echo "[FAIL] $svc is '$state' (expected 'active')"
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "SMOKE TEST FAILED"
  exit 1
fi

echo "SMOKE TEST PASSED"
exit 0
