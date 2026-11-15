#!/bin/sh
# The keyboard runs this with "show" or "hide". While it is up the buttons
# type; while it is down they browse. An app that brought its own controller
# layout (DONKEY_CONTROLLER) keeps it either way.
[ -z "$DONKEY_CONTROLLER" ] || exit 0
case "$1" in
  show) layout=keys ;;
  hide) layout=browse ;;
  *) exit 2 ;;
esac
[ -n "$DONKEY_PAD" ] || exit 1
exec busctl call org.shadowblip.InputPlumber "$DONKEY_PAD" \
  org.shadowblip.Input.CompositeDevice LoadProfilePath s \
  "$DONKEY_APP/controller/$layout.yaml"
