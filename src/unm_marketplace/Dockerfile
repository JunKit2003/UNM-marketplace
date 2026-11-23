# syntax=docker/dockerfile:1
# Local builds compile Flutter here. CI supplies the web files from its Flutter test job.
ARG FLUTTER_BUILD_STAGE=build
FROM scratch AS prebuilt
COPY ci-web/ /app/build/web/
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

FROM ${FLUTTER_BUILD_STAGE} AS web_artifacts

FROM nginx:1-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=web_artifacts /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s CMD wget -qO- http://127.0.0.1/healthz >/dev/null || exit 1
