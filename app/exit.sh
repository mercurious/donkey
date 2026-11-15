#!/bin/sh
# Close Donkey's Firefox; launch.sh notices and cleans up after it.
pid=$(cat /run/donkey/firefox.pid 2>/dev/null)
case "$pid" in
  '' | *[!0-9]*) exit 1 ;;
esac
kill -TERM "$pid"
