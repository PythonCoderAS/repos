#!/bin/sh

# Get a list of all repos, applying excludes, and save it to cache/repo-list-cached.txt
# If the cache file exists, read from it, otherwise, generate it
if [ -f cache/repo-list-cached.txt ]; then
    cat cache/repo-list-cached.txt
    exit 0
fi
gh-all-repos list PythonCoderAS --no-private --no-show-owner-name > /tmp/output.1.txt
grep -wvf config/exclude.txt /tmp/output.1.txt > cache/repo-list-cached.txt
cat cache/repo-list-cached.txt