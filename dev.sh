#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <container-name-suffix> [docker-options...]"
    exit 1
fi

container_name="dev-$1"
shift
extra_opts=("$@")

# Check if the container already exists
if podman container exists "$container_name"; then
    podman exec -it "$container_name" zsh
else
    podman run -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=/tmp -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --name "$container_name" -h "$container_name" --add-host "$container_name:127.0.0.1" -v $PWD:/workspace:U -v $HOME/.config/opencode/:/home/dev/.config/opencode/:U -v "${container_name}_home_data:/home/dev/" --network=host "${extra_opts[@]}" -itd dev
    podman exec -it "$container_name" zsh
fi
