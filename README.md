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

For example:

```bash
bosh deploy -d snort manifests/snort.yml \
    -o manifests/operators/network.yml \
    -v network-name=foo
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

For example:

```bash
bosh deploy -d snort manifests/snort.yml \
    -o manifests/operators/interface-name.yml \
    -v interface-name=wn7v8a123uqr-1
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
