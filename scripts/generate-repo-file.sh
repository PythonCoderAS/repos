#!/bin/bash

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
IS_FORK=[[ "$(echo "$REPO_DATA" | jq -r '.isFork')" == "true" ]]
IS_ARCHIVED=[[ "$(echo "$REPO_DATA" | jq -r '.isArchived')" == "true" ]]
IS_TEMPLATE=[[ "$(echo "$REPO_DATA" | jq -r '.isTemplate')" == "true" ]]
REPO_DESCRIPTION="$(echo "$REPO_DATA" | jq -r '.description')"
DEFAULT_BRANCH="$(echo "$REPO_DATA" | jq -r '.defaultBranchRef.name')"
HOMEPAGE_URL="$(echo "$REPO_DATA" | jq -r '.homepageUrl')"

cmp -s "config/empty-file.md" "readmes/$REPO.md" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    IS_STUB_FILE=0
else 
    IS_STUB_FILE=1
fi
REPO_README="$(cat "readmes/$REPO.md")"
EDIT_URL="https://github.com/$OWNER/repos/edit/main/readmes/$REPO.md"

curl -L -s --fail "https://$OWNER.github.io/$REPO/" > /dev/null
if [ $? -eq 0 ]; then
    HAS_GH_PAGES=1
else
    HAS_GH_PAGES=0
fi

if [ "$IS_STUB_FILE" ]; then
    REPO_README="$(curl -L -s --fail "https://raw.githubusercontent.com/$OWNER/$REPO/$DEFAULT_BRANCH/README.md")"
    EDIT_URL="https://github.com/$OWNER/$REPO/edit/$DEFAULT_BRANCH/README.md"
    if [ $? -ne 0 ]; then
        REPO_README="$REPO_DESCRIPTION"
        EDIT_URL=""
    fi
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
[ ! -z "$EDIT_URL" ] && EDIT_URL_LINE="<small>[Edit Here]($EDIT_URL)</small>"
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