#!/bin/bash

set -ex

# SOURCE_PATH=/home/serg/projects/fuel-main/build/packages/sources/fuelmenu
# SPEC_FILE=fuelmenu.spec
# SPEC_FILE_PATH=/home/serg/projects/fuel-main/packages/rpm/specs/${SPEC_FILE}
# RESULT_DIR=/tmp/packages

  # docker run -v ${SOURCE_PATH}:/opt/sandbox/SOURCES \
  #            -v ${SPEC_FILE_PATH}:/opt/sandbox/${SPEC_FILE} \
  #            -v ${RESULT_DIR}:/opt/sandbox/RPMS \
  #            -u 1000 \
  #            -t -i fuel/rpmbuild_env rpmbuild --nodeps -vv --define "_topdir /opt/sandbox" -ba /opt/sandbox/${SPEC_FILE}



SOURCE_PATH=/home/serg/projects/fuel-main/build/packages/sources
SPEC_FILE_PATH=/home/serg/projects/fuel-main/packages/rpm/specs
RESULT_DIR=/tmp/packages

rm -rf ${RESULT_DIR}
mkdir ${RESULT_DIR}

for pckgs in $(ls ${SOURCE_PATH}); do
docker run -v ${SOURCE_PATH}/${pckgs}:/opt/sandbox/SOURCES \
             -v ${SPEC_FILE_PATH}/${pckgs}.spec:/opt/sandbox/$(basename ${pckgs}).spec \
             -v ${RESULT_DIR}:/opt/sandbox/RPMS \
             -u ${UID} \
             -d \
             -t -i fuel/rpmbuild_env rpmbuild --nodeps -vv --define "_topdir /opt/sandbox" -ba /opt/sandbox/$(basename ${pckgs}).spec
done
