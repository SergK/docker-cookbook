#!/bin/bash

set -ex

SOURCE_PATH=/home/skulanov/projects/fuel-main/build/packages/sources/
SPEC_PATH=/home/skulanov/projects/fuel-main/packages/deb/specs/
RESULT_DIR=/tmp/packages
BUILD_SCRIPT=build_deb_in_docker.sh

docker run -v ${SOURCE_PATH}:/opt/sandbox/SOURCES \
           -v ${SPEC_PATH}:/opt/sandbox/SPECS \
           -v ${RESULT_DIR}:/opt/sandbox/DEB \
           -v ${PWD}/${BUILD_SCRIPT}:/opt/sandbox/${BUILD_SCRIPT} \
           -t -i fuel/debbuild_env /bin/bash /opt/sandbox/${BUILD_SCRIPT}
