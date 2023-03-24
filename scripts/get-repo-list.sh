#!/bin/bash

# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap '[ "$?" != "0" ] && echo "\"${last_command}\" command filed with exit code $?."' EXIT

# Get a list of all repos, applying excludes, and save it to cache/repo-list-cached.txt
# If the cache file exists, read from it, otherwise, generate it
mkdir -p cache
if [ -f cache/repo-list-cached.txt ]; then
    cat cache/repo-list-cached.txt
    exit 0
fi
gh-all-repos list PythonCoderAS --no-private --no-show-owner-name > /tmp/output.1.txt
grep -wvf config/exclude.txt /tmp/output.1.txt > cache/repo-list-cached.txt
cat cache/repo-list-cached.txt