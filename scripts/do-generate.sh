#!/bin/bash

# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
function errorfunc(){
    local error_code="$1"
    local last_command="$2"
    [ "$error_code" != "0" ] && echo "\"${last_command}\" command filed with exit code $error_code."
}
trap 'errorfunc "$?" "${last_command}"' EXIT

# GH ACTIONS WHY?

scripts/get-repo-list.sh | while read repo; do scripts/generate-repo-file.sh $repo; done