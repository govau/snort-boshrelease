# BOSH Release for Snort IDS

## Usage

### Setting up local environment

1. Assumes Bosh2 is installed with binary named `bosh`.

1. Setup a local BOSH2 environment with VBOX: <https://github.com/cloudfoundry/bosh-deployment>. Tip: use `export BOSH_ENVIRONMENT=vbox` to avoid needing to pass `-e vbox` to all subsequent `bosh` commands.

1. Remember to apply the provided BOSH cloud-config: <https://github.com/cloudfoundry/bosh-deployment/blob/master/warden/cloud-config.yml>

```bash
bosh update-cloud-config ./warden/cloud-config.yml
```

1. fetch a stemcell from bosh.io

```bash
bosh upload stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
```

### Deploying Default snort deployment

The base manifest `manifests/snort.yml` should "Just Work".
It uses `default` for vm_type, stemcell, persistent_disk_type, and networks as setup in the cloud-config above.

Snort is configured to log alerts with the [alert_fast output module](http://manual-snort-org.s3-website-us-east-1.amazonaws.com/node21.html#SECTION00362000000000000000)

### Updating snort rules

The snort configuration and rules are packaged in the snort-conf.tar.gz bosh blob.

These rules are kept up to date with a [concourse CI pipeline](tree/master/ci) which periodically downloads the latest community rules from snort.org.

The pipeline periodically:
- Fetches the current community rules using [pulledpork](https://github.com/shirkdog/pulledpork)
- Compares the downloaded snort.rules with the version in the snort-conf.tar.gz blob, and creates a new version of the blob if it has changed.
- The new blob is added and uploaded using `bosh add-blob` and `bosh upload-blobs`, and the new config/blobs.yml is checked into this repository.

A release must then be manually created with the latest blob version.

### Using Operator files

BOSH2 operator files allow you to extend/replace parts of the default deployment manifest.

#### Add filebeat - `manifests/operators/filebeat.yml`

This operator allows you to add `filebeat` to the snort instance. Filebeat is a logshipper from elastic (elastic.co).

For example:

```bash
bosh deploy -d snort manifests/snort.yml \
    -o manifests/operators/filebeat.yml \
    -v central-logging-listener=10.244.0.7:5044
```

#### network customisation - `manifests/operators/networking.yml`

This operator allows you to deploy to a cloud-config network that isn't `default` and set a static ip.

For example:

```bash
bosh deploy -d snort manifests/snort.yml \
    -o manifests/operators/networking.yml \
    -v network-name=foo
    -v static-ip=10.244.0.8
```

#### VM type - `manifests/operators/vm-type.yml`

By default snort uses the `default` vm_type.  This ops file allows you to change this.

For example:

```bash
bosh deploy -d snort manifests/snort.yml \
    -o manifests/operators/vm-type.yml \
    -v vm-type=foo
```

#### Log all packets for debugging - `manifests/operators/log-all-packets.yml`

This operator allows you to add a snort rule which will match all packets. This is useful for debugging.

For example:

```bash
bosh deploy -d snort manifests/snort.yml \
    -o manifests/operators/log-all-packets.yml
```

#### Set interface name - `manifests/operators/interface-name.yml`

By default snort will listen to lo and eth0. Use this file to change from eth0 to another interface. This is useful when testing on bosh-lite, as it seems to assign a random name to the network interface.

For ex
```bash
bosh deploy -d snort manifests/snort.yml \
    -o manifests/operators/interface-name.yml \
    -v interface-name=wn7v8a123uqr-1
```

## Local Development

You can make changes and create local dev releases. These can then be deployed locally with the `latest-release.yml` operator file.

```bash
bosh create-release --force --name snort

bosh upload-release

bosh deploy -d snort manifests/snort.yml \
  -o manifests/operators/latest-release.yml
```

## creating a final release

1.  create bosh final release (requires s3 credentials in `config/final.yml`)
```
export VERSION=x.y.z
bosh create-release --final --version=$VERSION --name=snort --tarball=releases/snort/snort-$VERSION.tgz
```
2. determine sha1 of tarball blob and update the `version`, `url` and `sha` details of the snort release in the `manifests/snort.yml` file
```
shasum releases/snort/snort-$VERSION.tgz
```
3. commit and push changes
```
git add releases .final_builds/ manifests/snort.yml
git commit -m"BOSH release $VERSION"
git tag v$VERSION
git push origin master
git push --tags
```
4. Create a release from the new tag and upload the tarball `releases/snort/snort-$VERSION.tgz`
