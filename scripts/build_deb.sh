#!/bin/bash

set -ex

SOURCE_PATH=/home/skulanov/projects/fuel-main/build/packages/sources/
SPEC_PATH=/home/skulanov/projects/fuel-main/packages/deb/specs/
RESULT_DIR=/tmp/packages

docker run -v ${SOURCE_PATH}:/opt/sandbox/SOURCES \
           -v ${SPEC_PATH}:/opt/sandbox/SPECS \
           -v ${RESULT_DIR}:/opt/sandbox/DEB \
           -t -i fuel/debbuild_env /bin/bash /opt/sandbox/build_deb_in_docker.sh
