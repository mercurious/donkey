#!/bin/sh
# Package Donkey and install it on a device over SSH, into /storage/apps/donkey
# (or DONKEY_ROOT/donkey). Firefox and logs already there are kept.
#   DONKEY_HOST  ssh destination (default root@sm8250-12gb.local)
#   DONKEY_KEY   ssh identity file (optional)
#   DONKEY_ROOT  parent directory on the device (default /storage/apps)
# Arguments go to install.sh, e.g. --update-firefox.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOST="${DONKEY_HOST:-root@sm8250-12gb.local}"
DEST="${DONKEY_ROOT:-/storage/apps}"
SSH_OPTS="${DONKEY_KEY:+-i $DONKEY_KEY}"

"$ROOT/tools/package.sh" >/dev/null
# shellcheck disable=SC2086
scp -q $SSH_OPTS "$ROOT/dist/donkey-aarch64.tar.gz" "$HOST:/tmp/"
# shellcheck disable=SC2086
ssh $SSH_OPTS "$HOST" "mkdir -p $DEST && tar -xzf /tmp/donkey-aarch64.tar.gz -C $DEST && $DEST/donkey/install.sh $*"
