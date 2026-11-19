#!/usr/bin/env bash
# Runs on the VPS (CI calls it over SSH). Deploys one image tag, checks health,
# and puts the previous tag back if the new release is unhealthy.
#
#   ./remote-deploy.sh <image-tag>          e.g. a commit SHA
#   SKIP_PULL=1 ./remote-deploy.sh <tag>    use images already on this machine (local testing)
set -euo pipefail

TAG=${1:?usage: remote-deploy.sh <image-tag>}
cd "$(dirname "$0")"
[ -f .env ] || { echo "error: .env is missing in $(pwd) (see docs/deploy-handoff.md)"; exit 1; }

COMPOSE=(docker compose -f compose.prod.yaml)
PREV=$(cat .current_tag 2>/dev/null || true)
BIND=$(grep -E '^WEB_BIND=' .env | tail -1 | cut -d= -f2- || true)
BIND=${BIND:-127.0.0.1:8090}
TIMEOUT=${HEALTH_TIMEOUT:-90}

deploy() {
  if [ "${SKIP_PULL:-0}" != 1 ]; then IMAGE_TAG=$1 "${COMPOSE[@]}" pull api web; fi
  IMAGE_TAG=$1 "${COMPOSE[@]}" up -d --remove-orphans
}

healthy() {
  for _ in $(seq 1 "$TIMEOUT"); do
    if curl -fsS "http://$BIND/api/health" 2>/dev/null | grep -q '"ok":true'; then return 0; fi
    sleep 1
  done
  return 1
}

echo "deploying $TAG (previous: ${PREV:-none})"
if deploy "$TAG" && healthy; then
  echo "$TAG" > .current_tag
  docker image prune -f >/dev/null || true
  echo "deployed $TAG"
  exit 0
fi

echo "release $TAG failed its health check"
if [ -n "$PREV" ] && [ "$PREV" != "$TAG" ]; then
  if deploy "$PREV" && healthy; then
    echo "rolled back to $PREV"
  else
    echo "ROLLBACK FAILED: the site may be down. Check: docker compose -f compose.prod.yaml logs"
  fi
else
  echo "no previous release to roll back to"
fi
exit 1
