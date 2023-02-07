#!/usr/bin/env bash

set -e -o pipefail

# Password is expected to be in the file referenced by the PASSWD_FILE environment variable
SAMBA_TOOL_PARAMS="--URL=ldap://$AD_DOMAIN --username=$AD_USERNAME"

COMMAND=$1
GROUP=$2
USER=$3

case $COMMAND in
    "add")
        samba-tool group addmembers $SAMBA_TOOL_PARAMS "$GROUP" "$USER"
        ;;
    "remove")
        samba-tool group removemembers $SAMBA_TOOL_PARAMS "$GROUP" "$USER"
        ;;
    "check")
        samba-tool group listmembers $SAMBA_TOOL_PARAMS "$GROUP" | grep ^"$USER"$ > /dev/null
        ;;
    *)
        echo "Unknown command: $COMMAND"
        exit 1
        ;;
esac
