# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1.2.15 AS base
ARG VERSION=${VERSION:-[VERSION]}

ARG BUILD_PKG="apt-transport-https ca-certificates curl gnupg lsb-release"

# Install Docker CLI
RUN apt-get update \
  && apt-get install -qq -y --no-install-recommends ${BUILD_PKG} \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update \
  && apt-get install -qq -y --no-install-recommends docker-ce-cli \
  && apt-get remove -y ${BUILD_PKG} \
  && apt-get clean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

WORKDIR /opt
RUN bun add @modelcontextprotocol/inspector@$VERSION

# run the app
ARG SERVER_PORT=6277
EXPOSE 6274
EXPOSE ${SERVER_PORT}

HEALTHCHECK --interval=10s --timeout=3s CMD bash -c ":> /dev/tcp/127.0.0.1/${SERVER_PORT}" || /opt/node_modules/.bin/mcp-inspector

RUN echo '{"mcpServers": {"mcp-test": {}}}' > /opt/mcp-config.json
ENTRYPOINT [ \
  "bun", \
  "/opt/node_modules/.bin/mcp-inspector", \
  "--config", \
  "/opt/mcp-config.json", \
  "--server", \
  "mcp-test" \
  ]
