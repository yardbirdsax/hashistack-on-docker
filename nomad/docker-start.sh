#!/usr/bin/env bash
/usr/local/bin/consul agent -config-dir=/etc/consul.d &
/usr/local/bin/nomad agent -config /etc/nomad.d -dev &

function term {
  echo "Caught termination request, waiting for processes to exit."
  wait_terminate consul
}

function wait_terminate() {
  PROCESS_NAME=$1
  TOTAL_WAIT=0

  while sleep 5; do
    ps aux | grep $PROCESS_NAME | grep -q -v grep
    PROCESS_STATUS=$?
    if [ $PROCESS_STATUS -eq 0 ]; then
      $TOTAL_WAIT += 5
      echo "Process $PROCESS_NAME is still running, total wait time is $TOTAL_WAIT seconds."
      if [ $TOTAL_WAIT -gt 60 ]; then
        return 1
      fi
    else
      return 0
    fi
  done
}

trap term SIGINT
trap term SIGTERM

while sleep 60; do
  ps aux | grep consul | grep -q -v grep
  CONSUL_STATUS=$?

  if [ $CONSUL_STATUS -ne 0 ]; then
    echo "Consul is not running, exiting."
    exit 1
  else
    echo "Consul is running."
  fi

  ps aux | grep nomad | grep -q -v grep
  NOMAD_STATUS=$?

  if [ $NOMAD_STATUS -ne 0 ]; then
    echo "Nomad is not running, exiting."
    exit 1
  else
    echo "Nomad is running."
  fi

done