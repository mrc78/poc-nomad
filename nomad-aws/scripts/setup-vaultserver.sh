#!/bin/bash
image=${1:-"vault:0.9.0"}

sudo mkdir -p /etc/vault.d

cat << EOF | sudo tee /etc/vault.d/storage.hcl
storage "consul" {
    address = "127.0.0.1:8500"
}
EOF

cat << EOF | sudo tee /etc/vault.d/listener.hcl
storage "consul" {
    address = "127.0.0.1:8200"
    tls_disable = "true"
}
EOF

docker pull "$image"

docker run -d --name=vault \
    --cap-add IPC_LOCK \
    -v /etc/vault.d:/etc/vault.d \
    --net=host \
    --restart=always \
    "$image" \
    server \
    -config '/etc/vault.d'
