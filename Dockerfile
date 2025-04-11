# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 AS base
ARG VERSION=${VERSION:-[VERSION]}

ARG BUILD_PKG="apt-transport-https ca-certificates curl gnupg lsb-release"

# Install Docker CLI
RUN apt update \
  && apt install -qq -y --no-install-recommends ${BUILD_PKG} \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt update \
  && apt install -qq -y --no-install-recommends docker-ce-cli \
  && apt remove -y ${BUILD_PKG} \
  && apt-get clean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

WORKDIR /opt
RUN bun i @modelcontextprotocol/inspector@$VERSION

# run the app
EXPOSE 6274
EXPOSE 6277

HEALTHCHECK --interval=30s --timeout=5s CMD bash -c ':> /dev/tcp/127.0.0.1/6277' || exit 1

ENTRYPOINT ["/opt/node_modules/.bin/mcp-inspector"]
