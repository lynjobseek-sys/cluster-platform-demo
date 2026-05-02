default:
    @just --list

build:
    kcl run models/stacks -o manifests/main.yaml

lint:
    conftest verify --policy .policy
    conftest test manifests/

clean:
    rm -f manifests/main.yaml

up:
    cd local-demo && ./setup.sh && ./clusters.sh && ./bootstrap.sh && ./verify.sh

down:
    cd local-demo && ./teardown.sh
