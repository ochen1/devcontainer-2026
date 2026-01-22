#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <container-name-suffix>"
    exit 1
fi

container_name="dev-$1"

# Check if the container already exists
if podman container exists "$container_name"; then
    podman exec -it "$container_name" zsh
else
    podman run -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=/tmp -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $PWD:/workspace --name "$container_name" -h "$container_name" -v $HOME/.config/opencode/:/home/dev/.config/opencode/ -v "$1_home_data:/home/dev/" --network=host -itd dev
    podman exec -it "$container_name" zsh
fi
