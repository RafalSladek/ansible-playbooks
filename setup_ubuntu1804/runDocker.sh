#!/bin/bash
#set -x

image_name=ubuntuforansible
contianer_name=ansiblelocal

echo "build docker image"
docker build -t $image_name .

docker stop $contianer_name > /dev/null 2>&1
docker rm $contianer_name > /dev/null 2>&1

echo "run docker container"

# If you want have iptables access within your containers, you need to enable specific capabilities via the --cap-add=NET_ADMIN switch when running the container initially.
docker run --cap-add=NET_ADMIN -it --rm \
    -v $(pwd):/root/playbook \
    -v $HOME/.ssh:/root/.ssh \
    -w /root/playbook \
    --name $contianer_name \
    $image_name