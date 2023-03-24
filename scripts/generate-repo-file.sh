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
trap 'errorfunc "$?" "${last_command}"' ERR

OWNER="PythonCoderAS"
REPO="$1"

if [ -z "$REPO" ]; then
    echo "Usage: $0 <repo>"
    exit 1
fi

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

REPO_DATA="$(gh repo view $OWNER/$REPO --json isFork,isArchived,isTemplate,homepageUrl,description,name,defaultBranchRef)"
mkdir -p cache
echo "$REPO_DATA" > "cache/$REPO.json"
FORK_DATA="$(echo "$REPO_DATA" | jq -r '.isFork')"
if [[ "$FORK_DATA" == "true" ]]; then
    IS_FORK=1
else
    IS_FORK=0
fi
ARCHIVE_DATA="$(echo "$REPO_DATA" | jq -r '.isArchived')"
if [[ "$ARCHIVE_DATA" == "true" ]]; then
    IS_ARCHIVED=1
else
    IS_ARCHIVED=0
fi
TEMPLATE_DATA="$(echo "$REPO_DATA" | jq -r '.isTemplate')"
if [[ "$TEMPLATE_DATA" == "true" ]]; then
    IS_TEMPLATE=1
else
    IS_TEMPLATE=0
fi
REPO_DESCRIPTION="$(echo "$REPO_DATA" | jq -r '.description')"
DEFAULT_BRANCH="$(echo "$REPO_DATA" | jq -r '.defaultBranchRef.name')"
HOMEPAGE_URL="$(echo "$REPO_DATA" | jq -r '.homepageUrl')"

set +e
cmp -s "config/empty-file.md" "readmes/$REPO.md" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    IS_STUB_FILE=0
else 
    IS_STUB_FILE=1
fi
set -e
REPO_README="$(cat "readmes/$REPO.md")"
EDIT_URL="https://github.com/$OWNER/repos/edit/main/readmes/$REPO.md"

set +e
curl -L -s --fail "https://$OWNER.github.io/$REPO/" > /dev/null
if [ $? -eq 0 ]; then
    HAS_GH_PAGES=1
else
    HAS_GH_PAGES=0
fi
set -e
if [ "$IS_STUB_FILE" ]; then
    set +e
    REPO_README="$(curl -L -s --fail "https://raw.githubusercontent.com/$OWNER/$REPO/$DEFAULT_BRANCH/README.md")"
    EDIT_URL="https://github.com/$OWNER/$REPO/edit/$DEFAULT_BRANCH/README.md"
    if [ $? -ne 0 ]; then
        REPO_README="$REPO_DESCRIPTION"
        EDIT_URL=""
    fi
    set -e
fi

REPO_TYPE=""
if [ "$IS_ARCHIVED" ]; then
    REPO_TYPE="Archived "
fi
if [ "$IS_FORK" ]; then
    REPO_TYPE="$REPO_TYPE Fork"
fi
if [ "$IS_TEMPLATE" ]; then
    REPO_TYPE="$REPO_TYPE Template"
fi
REPO_TYPE="$(trim "$REPO_TYPE")"
[ ! -z "$REPO_TYPE" ] && REPO_TYPE_LINE="Type: $REPO_TYPE"
[ ! -z "$HOMEPAGE_URL" ] && HOMEPAGE_URL_LINE="Homepage: [$HOMEPAGE_URL]($HOMEPAGE_URL)"
[ ! -z "$EDIT_URL" ] && EDIT_URL_LINE="<small>

[Edit Here]($EDIT_URL)

</small>"
[ ! -z "$HAS_GH_PAGES" ] && GH_PAGES_LINE="GitHub Pages Site: https://$OWNER.github.io/$REPO/"

mkdir -p "generated"
cat -s > "generated/$REPO.md" << EOF

# [$REPO](https://github.com/$OWNER/$REPO)

$REPO_DESCRIPTION

$REPO_TYPE_LINE
$HOMEPAGE_URL_LINE
$GH_PAGES_LINE

----

$REPO_README

$EDIT_URL_LINE
EOF

exit 0