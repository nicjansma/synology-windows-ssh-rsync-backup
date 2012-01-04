#!/bin/sh

ROOTDIR=$1

case "$SSH_ORIGINAL_COMMAND" in
    *\&*)
        echo "Rejected"
        ;;
    *\;*)
        echo "Rejected"
        ;;
    rsync\ --server*$ROOTDIR*)
        $SSH_ORIGINAL_COMMAND
        ;;
    *)
        echo "Rejected"
        ;;
esac