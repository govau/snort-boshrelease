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

### Deploying Default graylog deployment

The base manifest `manifests/graylog.yml` should "Just Work".
It is setup with with BOSH linking so no static-ip addresses or specific settings should be required.  It uses `default` for vm_type, stemcell, persistent_disk_type, and networks as setup in the cloud-config above.

### Using Operator files

BOSH2 operator files allow you to extend/replace parts of the default deployment manifest.

#### network customisation - `manifests/operators/network.yml`

This operator allows you to deploy to a cloud-config network that isn't `default`.
eg.

```bash
bosh deploy -n -d snort manifests/snort.yml \
    -o manifests/operators/network.yml \
    -v network-name=foo
```

## Local Development

You can make changes and create local dev releases.

```bash
bosh create-release --force --name snort

bosh upload-release

bosh deploy -d snort manifests/snort.yml
```

### Final releases

todo

To share final releases:

```
bosh create release --final
```

By default the version number will be bumped to the next major number. You can specify alternate versions:


```
bosh create release --final --version 2.1
```
