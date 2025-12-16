#!/bin/bash
docker run --rm -it \
    --user $(id -u):$(id -g) \
    --hostname sandbox \
    -v $HOME:/home/user \
    user-shell
