# syntax=docker/dockerfile:1
# Build the Flutter web app, then serve it with nginx.
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
# Optional build secret `npm_ca`: CA bundle for TLS-inspecting networks (local builds only).
RUN --mount=type=secret,id=npm_ca,required=false \
    if [ -s /run/secrets/npm_ca ]; then cp /run/secrets/npm_ca /etc/ssl/certs/ca-certificates.crt; fi; \
    flutter pub get
COPY . .
# --no-web-resources-cdn: serve CanvasKit ourselves instead of from gstatic.com.
RUN --mount=type=secret,id=npm_ca,required=false \
    if [ -s /run/secrets/npm_ca ]; then cp /run/secrets/npm_ca /etc/ssl/certs/ca-certificates.crt; fi; \
    flutter build web --release --no-web-resources-cdn

FROM nginx:1-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
