# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 AS base
ARG VERSION=${VERSION:-[VERSION]}

WORKDIR /opt
RUN bun i @modelcontextprotocol/inspector@$VERSION

# run the app
EXPOSE 6274
USER bun

HEALTHCHECK --interval=30s --timeout=5s CMD bash -c ':> /dev/tcp/127.0.0.1/6277' || exit 1

ENTRYPOINT ["/opt/node_modules/.bin/mcp-inspector"]
