# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 AS base
ARG VERSION=${VERSION:-[VERSION]}
WORKDIR /workspace

RUN bun i @modelcontextprotocol/inspector@$VERSION

# run the app
EXPOSE 6274
USER bun
ENTRYPOINT [ "/workspace/node_modules/.bin/mcp-inspector" ]
