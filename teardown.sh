#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [-v] <container-name-suffix>"
    echo "  -v    Remove associated volume as well"
    exit 1
}

REMOVE_VOLUME=0

while getopts ":v" opt; do
  case $opt in
    v)
      REMOVE_VOLUME=1
      ;;
    *)
      usage
      ;;
  esac
done

shift $((OPTIND -1))

if [ "$#" -ne 1 ]; then
    usage
fi

SUFFIX="$1"
CONTAINER_NAME="dev-$SUFFIX"
VOLUME_NAME="${SUFFIX}_home_data"

# Stop and remove the container if it exists
if podman ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    podman kill "$CONTAINER_NAME"
    podman rm "$CONTAINER_NAME"
else
    echo "Container $CONTAINER_NAME does not exist."
fi

# Optionally remove the volume
if [ "$REMOVE_VOLUME" -eq 1 ]; then
    if podman volume ls --format '{{.Name}}' | grep -q "^$VOLUME_NAME$"; then
        podman volume rm "$VOLUME_NAME"
    else
        echo "Volume $VOLUME_NAME does not exist."
    fi
fi
