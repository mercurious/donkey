#!/bin/sh
# Package Donkey and install it on a device over SSH.
#   DONKEY_HOST  ssh destination (default root@sm8250-12gb.local)
#   DONKEY_KEY   ssh identity file (optional)
# Arguments go to install.sh, e.g. --update-firefox.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOST="${DONKEY_HOST:-root@sm8250-12gb.local}"
SSH_OPTS="${DONKEY_KEY:+-i $DONKEY_KEY}"

tarball=$("$ROOT/tools/package.sh" | tail -n 1)
name=$(basename "$tarball" .tar.gz)

scp -q $SSH_OPTS "$ROOT/$tarball" "$HOST:/tmp/"
ssh $SSH_OPTS "$HOST" \
  "cd /tmp && rm -rf $name && tar -xzf $name.tar.gz && ./$name/install.sh $*"
