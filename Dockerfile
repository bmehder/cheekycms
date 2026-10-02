FROM ghcr.io/gleam-lang/gleam:v1.18.1-erlang-alpine AS build

WORKDIR /app
COPY gleam.toml manifest.toml ./
RUN gleam deps download
COPY src ./src
RUN gleam export erlang-shipment

FROM erlang:29-alpine AS runtime

RUN addgroup -S cheekycms && adduser -S cheekycms -G cheekycms
WORKDIR /app
COPY --from=build --chown=cheekycms:cheekycms /app/build/erlang-shipment ./
COPY --chown=cheekycms:cheekycms content ./content

ENV CHEEKYCMS_HOST=0.0.0.0 \
    CHEEKYCMS_PORT=4000 \
    CHEEKYCMS_CONTENT_ROOT=/app/content \
    CHEEKYCMS_ALLOWED_ORIGINS=*

EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --spider http://127.0.0.1:${CHEEKYCMS_PORT}/health || exit 1

USER cheekycms
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
CMD ["run"]
