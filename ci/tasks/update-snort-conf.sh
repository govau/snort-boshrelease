#!/bin/bash

# set -e -u -x

set -euox pipefail
IFS=$'\n\t'

cd pulledpork-output

cat << EOF > config/private.yml
---
blobstore:
  provider: s3
  options:
    access_key_id: $S3_ACCESS_KEY_ID
    secret_access_key: $S3_SECRET_ACCESS_KEY
EOF

bosh -n sync-blobs
SNORT_RULES_SHA1=$(cat ci/config/snort-conf/rules/snort.rules | sha1sum)
if [ "${SNORT_RULES_SHA1}" != "$(tar -xOf blobs/snort-conf.tar.gz snort-conf/rules/snort.rules | sha1sum)" ] ; then

  echo "snort rules have changed"

  # create new snort-conf.tar.gz
  tar czvf snort-conf.tar.gz -C ci/config snort-conf

  bosh -n add-blob snort-conf.tar.gz snort-conf.tar.gz
  bosh -n upload-blobs
  cp -rf ../snort-boshrelease-git/. ../snort-boshrelease-git-modified
  cp config/blobs.yml ../snort-boshrelease-git-modified/config
  cd ../snort-boshrelease-git-modified

  if [[ -z $(git config --global user.email) ]]; then
    git config --global user.email "dta-snort-ci@@users.noreply.github.com"
  fi
  if [[ -z $(git config --global user.name) ]]; then
    git config --global user.name "dta-snort-ci"
  fi

  git commit config/blobs.yml -m"Update rules

snort.rules SHA1: ${SNORT_RULES_SHA1}"
else
  echo "snort rules have not changed"
fi
