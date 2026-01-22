#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <container-name-suffix>"
    exit 1
fi

podman run -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=/tmp -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $PWD:/workspace --name "dev-$1" -h "dev-$1" -v $HOME/.config/opencode/:/home/dev/.config/opencode/ -v "$1_home_data:/home/dev/" --network=host -itd dev
podman exec -it "dev-$1" zsh
