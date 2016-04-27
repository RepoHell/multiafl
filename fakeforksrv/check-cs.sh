#!/bin/bash
set -eu
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATH="$PATH:../../../darpa/interact/cb-testing/"
PORT=$(( 2000 + ($RANDOM % 3000) ))

if (( $# > 1 )); then
    POLLS_DIR="$1"
    shift
    CBS="$@"
elif (( $# == 1 )); then
    SAMPLE_NAME="$1"
    SAMPLE_DIR="../../../samples/examples/$SAMPLE_NAME"
    [ -d "$SAMPLE_DIR" ] || SAMPLE_DIR="../../../samples/cqe-challenges/$SAMPLE_NAME"
    [ -d "$SAMPLE_DIR" ] || { echo "Cannot find sample dir! Run with full paths. Looked in ../../samples/{examples,cqe-challenges}/$SAMPLE_DIR"; exit 2; }
    POLLS_DIR="$SAMPLE_DIR/poller/for-testing"
    [ -d "$POLLS_DIR" ] || POLLS_DIR="$SAMPLE_DIR/poller/for-release/"
    [ -d "$POLLS_DIR" ] || { echo "Found sample dir but not its poller/for-{testing,release}/? (sample dir: $SAMPLE_DIR)"; exit 1; }
    CBS="$SAMPLE_DIR/bin/${SAMPLE_NAME}_?"
else
    echo -e "Usage: $0 POLLS_DIR CB_0 [CB_1] [...]\n       SAMPLE_NAME"
    exit 1
fi
ls "$POLLS_DIR"/*.xml >/dev/null || { echo "No *.xml files in polls dir $POLLS_DIR"; exit 3; }
ls $CBS >/dev/null || { echo "No CBs $CBS"; exit 3; }

./run_via_fakeforksrv --port $PORT $CBS &

RET=1
cb-replay --host 127.0.0.1 --port $PORT "$POLLS_DIR"/*.xml | egrep 'failed: [1-9]' || RET=0

kill %
exit $RET
