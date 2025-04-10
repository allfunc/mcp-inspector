#!/usr/bin/env sh

DIR="$(
  cd "$(dirname "$0")"
  pwd -P
)"

IMAGE_NAME=$(${DIR}/support/remoteImage.sh)
VERSION=$(${DIR}/support/VERSION.sh)

build() {
  DOCKER_BUILDKIT=1 docker build --progress=plain \
    --build-arg VERSION=$VERSION \
    -t $IMAGE_NAME .
}

enter() {
  docker run --rm -it \
    -v $HOME/.mcp-credentials:/run/secrets/mcp \
    --entrypoint sh \
    $IMAGE_NAME
}

run() {
  docker run --rm -it \
    -v $HOME/.mcp-credentials:/run/secrets/mcp \
    -p 6274:6274 \
    $IMAGE_NAME
}

login() {
  IS_LOGIN=$(echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_LOGIN" --password-stdin 2>&1)
  if [ -z "${IS_LOGIN+y}" ]; then
    echo "Not get login info."
    exit 1
  elif ! expr "${IS_LOGIN}" : ".*Succeeded.*" > /dev/null; then
    echo ${IS_LOGIN}
    echo "Login not Succeeded."
    exit 2
  else
    echo "Login Succeeded."
    exit 0
  fi
}

getJSONField() {
  text=$1
  field=$2
  echo $text | sed -n 's|.*"'${field}'"\s*:\s*"\([^"]*\)".*|\1|p'
}

getToken() {
  RESULT=$(
    curl -kX POST \
      -H "Content-Type: application/json" \
      -d '{"username": "'$DOCKER_LOGIN'", "password": "'$DOCKER_PASSWORD'"}' \
      https://hub.docker.com/v2/users/login
  )
  echo $(getJSONField $RESULT token)
}

updateDockerHubDesc() {
  DIR="$(
    cd "$(dirname "$0")"
    pwd -P
  )"
  remoteImage=$(${DIR}/support/remoteImage.sh)
  dockerHubImage=$(DOCKER_HUB=1 ${DIR}/support/remoteImage.sh)
  token=$(getToken)
  if [ -e "README.md" ]; then
    full_description=$(jq -s -R . README.md)
  fi
  data="{\"full_description\": ${full_description:-""} }"
  URL=https://hub.docker.com/v2/repositories/${dockerHubImage:-$remoteImage}
  echo
  echo $URL
  echo
  RESULT=$(
    curl -kX PATCH $URL \
      -H "Content-Type: application/json" \
      -H "Authorization: JWT $token" \
      -d "$data"
  )
  echo $RESULT
}

case "$1" in
  login)
    login
    ;;
  updateDockerHubDesc)
    updateDockerHubDesc
    ;;
  enter)
    enter
    ;;
  run)
    run
    ;;
  b)
    build
    ;;
  *)
    echo "$0 [b|enter|run]"
    ;;
esac

exit $?
