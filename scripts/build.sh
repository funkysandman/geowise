#!/bin/bash
set -e

figlet Build

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}"/../scripts/load-env.sh
BINARIES_OUTPUT_PATH="${DIR}/../artifacts/build/"
WEBAPP_ROOT_PATH="${DIR}/..//app/"

rm -rf ${BINARIES_OUTPUT_PATH} && mkdir -p ${BINARIES_OUTPUT_PATH}

cd ./app
zip -r ${BINARIES_OUTPUT_PATH}/app.zip .
