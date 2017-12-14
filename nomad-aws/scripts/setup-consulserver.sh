#!/bin/bash
consulimage=${1:-"consul:1.0.0"}
key=${2}

sudo mkdir /etc/consul.d
echo "{\"encrypt\":\"${key}\"}"  | sudo tee /etc/consul.d/encrypt.json > /dev/null

docker pull "$consulimage"

docker run -d --name=consul \
    -v consul:/consul/data \
    -v /etc/consul.d:/consul/config \
    --net=host \
    --restart=always \
    "$consulimage" \
    agent \
    -config-dir /consul/config \
    -retry-join 'provider=aws tag_key=consul tag_value=poc-nomad-consul' \
    -bind '{{ GetInterfaceIP "eth0" }}' \
    -server \
    -client '{{ GetInterfaceIP "eth0" }} 127.0.0.1 172.17.0.1' \
    -bootstrap-expect 3

sudo rm /etc/consul.d/encrypt.json
