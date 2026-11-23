#!/usr/bin/env bash
# Checks the web image's nginx routing against a stub api.
#   IMAGE=unm-marketplace-web ./src/unm_marketplace/nginx/test.sh
set -euo pipefail
IMAGE=${IMAGE:-unm-marketplace-web}
NET=unm-nginx-test-$$
PORT=${PORT:-18080}
cleanup() { docker rm -f "$NET-api" "$NET-web" >/dev/null 2>&1 || true; docker network rm "$NET" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker network create "$NET" >/dev/null
# Stub api: echoes method, path and the headers nginx forwards.
docker run -d --name "$NET-api" --network "$NET" --network-alias api node:24-alpine node -e '
require("http").createServer((q, s) => {
  s.writeHead(404, { "content-type": "application/json" });
  s.end(JSON.stringify({ stub: true, url: q.url, host: q.headers.host, proto: q.headers["x-forwarded-proto"],
    connection: q.headers.connection, upgrade: q.headers.upgrade || null }));
}).listen(3000)' >/dev/null
docker run -d --name "$NET-web" --network "$NET" -p "127.0.0.1:$PORT:80" "$IMAGE" >/dev/null
for _ in $(seq 1 30); do curl -sf "http://127.0.0.1:$PORT/" >/dev/null && break; sleep 0.5; done

fail=0
check() { if eval "$2"; then echo "ok   - $1"; else echo "FAIL - $1"; fail=1; fi; }
B="http://127.0.0.1:$PORT"

check "loopback health check serves the Flutter shell" \
  'docker exec "$NET-web" wget -qO- http://127.0.0.1/healthz | grep -q flutter_bootstrap.js'
check "health check is restricted to loopback" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$B/healthz")" = 403 ]'
check "health probes stay out of the access log" \
  'logs=$(docker logs "$NET-web" 2>&1) && ! grep -Eq "GET /healthz HTTP/[0-9.]+. [0-9]{3} " <<< "$logs"'

check "deep link /listing/42 serves the app" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" $B/listing/42)" = 200 ] && curl -s $B/listing/42 | grep -q flutter_bootstrap.js'
check "deep link /messages/7 serves the app" 'curl -s $B/messages/7 | grep -q flutter_bootstrap.js'
check "unknown /api path goes to the api, not index.html" 'curl -s $B/api/nope | grep -q "\"stub\":true"'
check "Host header keeps the port" 'curl -s $B/api/echo | grep -q "\"host\":\"127.0.0.1:$PORT\""'
check "X-Forwarded-Proto from the host nginx is kept" \
  'curl -s -H "X-Forwarded-Proto: https" $B/api/echo | grep -q "\"proto\":\"https\""'
check "X-Forwarded-Proto defaults to http" 'curl -s $B/api/echo | grep -q "\"proto\":\"http\""'
check "/images is proxied" 'curl -s $B/images/x.webp | grep -q "\"url\":\"/images/x.webp\""'
check "socket.io gets WebSocket upgrade headers" \
  'curl -s -H "Upgrade: websocket" -H "Connection: Upgrade" "$B/socket.io/?EIO=4&transport=websocket" | grep -q "\"upgrade\":\"websocket\""'
check "socket.io keeps the Host port and forwarded proto (same-origin check)" \
  'r=$(curl -s -H "Upgrade: websocket" -H "Connection: Upgrade" -H "X-Forwarded-Proto: https" "$B/socket.io/?EIO=4&transport=websocket"); echo "$r" | grep -q "\"host\":\"127.0.0.1:$PORT\"" && echo "$r" | grep -q "\"proto\":\"https\""'
check "/images keeps the Host header" 'curl -s $B/images/x.webp | grep -q "\"host\":\"127.0.0.1:$PORT\""'
check "service worker is revalidated" 'curl -sI $B/flutter_service_worker.js | grep -qi "cache-control: no-cache"'
check "index.html is revalidated" 'curl -sI $B/ | grep -qi "cache-control: no-cache"'
check "main.dart.js is served gzipped" 'curl -sI -H "Accept-Encoding: gzip" $B/main.dart.js | grep -qi "content-encoding: gzip"'
check "uploads up to 40 MB are accepted by nginx" \
  '[ "$(head -c 20000000 /dev/zero | curl -s -o /dev/null -w "%{http_code}" -X POST --data-binary @- $B/api/listings)" = 404 ]'
check "regular requests are still logged" \
  'docker logs "$NET-web" 2>&1 | grep -q "GET /listing/42 "'
exit $fail
