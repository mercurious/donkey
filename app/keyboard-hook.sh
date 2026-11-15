#!/bin/sh
# The keyboard runs this with "show" or "hide". While it is up the buttons
# type; while it is down they browse.
case "$1" in
  show) layout=keys ;;
  hide) layout=browse ;;
  *) exit 2 ;;
esac
[ -n "$DONKEY_PAD" ] || exit 1
exec busctl call org.shadowblip.InputPlumber "$DONKEY_PAD" \
  org.shadowblip.Input.CompositeDevice LoadProfilePath s \
  "/storage/apps/donkey/controller/$layout.yaml"
