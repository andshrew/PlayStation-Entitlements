#!/bin/bash

# https://github.com/andshrew/PlayStation-Entitlements
# Version: {{GIT_TAG_NAME}}/{{GIT_COMMIT_REF}}
#
# MIT License
# 2025 GPT4.1, andshrew

datetime=$(date "+%Y-%m-%d-%H%M%S")
default_save_path="$HOME/psn-entitlements-$datetime.json"

echo "PlayStation Network Entitlements Downloader"
echo "https://github.com/andshrew/PlayStation-Entitlements"
echo "Version: {{GIT_TAG_NAME}}/{{GIT_COMMIT_REF}}"
echo "Shell: $SHELL"
echo "Bash Version: $BASH_VERSION"
echo ""

echo "Get your npsso token from https://ca.account.sony.com/api/v1/ssocookie"
echo -n "Enter your npsso token (input hidden): "
stty -echo
read -r npsso
stty echo
echo

echo "Enter the file path to save the entitlements JSON [default: $default_save_path]:"
read -r save_path
if [ -z "$save_path" ]; then
  save_path="$default_save_path"
else
  if [[ ! "$save_path" =~ ^(\.?\.?/)?([A-Za-z0-9._-]+/)*[A-Za-z0-9._-]+$ ]]; then
    echo "Entered value is not a valid file path."
    exit 1
  fi
fi

if [ -f "$save_path" ]; then
  echo -n "File path already exists, Y to overwrite [default N]: "
  read -r overwrite_file
  if [[ ! "$overwrite_file" =~ ^(y|Y)$ ]]; then
    exit 1
  fi
fi

auth_url="https://ca.account.sony.com/api/authz/v3/oauth/token"
auth_header="Authorization: Basic MDk1MTUxNTktNzIzNy00MzcwLTliNDAtMzgwNmU2N2MwODkxOnVjUGprYTV0bnRCMktxc1A="
auth_body="token_format=jwt&grant_type=sso_token&npsso=$npsso&scope=psn:mobile.v2.core psn:clientapp"

echo "Authenticating..."

auth_response=$(curl -s -X POST "$auth_url" \
  -H "$auth_header" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "$auth_body")

access_token=$(echo "$auth_response" | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')

if [ -z "$access_token" ]; then
  echo "Error: Unable to obtain access token."
  echo "Response:"
  echo "$auth_response"
  exit 1
fi

echo "Authentication successful."

limit=500
offset=0
fields="fields=titleMeta,gameMeta,conceptMeta,rewardMeta,rewardMeta.retentionPolicy,drmdef,drmdef.contentType,skuMeta,productMeta,cloudMeta,metarev,entitlementAttributes"
api_url_base="https://m.np.playstation.com/api/entitlement/v2/users/me/internal/entitlements"

entitlements_temp="$(mktemp)"
meta_temp="$(mktemp)"

echo "Fetching entitlements (paging if required)..."

page=0
while : ; do
  query="${api_url_base}?${fields}&limit=${limit}&offset=${offset}"
  api_response=$(curl -s -X GET "$query" \
    -H "Authorization: Bearer $access_token")

  if [ "$page" -eq 0 ]; then
    # Save metadata from first page
    echo "$api_response" | jq '{revisionId, metaRevisionId, start, totalResults}' > "$meta_temp"
  fi

  # Extract entitlements array and append to temp file
  echo "$api_response" | jq -c '.entitlements[]' >> "$entitlements_temp"

  total_results=$(echo "$api_response" | jq '.totalResults')
  fetched_count=$(( (page + 1) * limit ))
  offset=$((offset + limit))
  page=$((page + 1))

  if [ "$offset" -ge "$total_results" ]; then
    break
  fi
done

# Build final output
jq -n \
  --argjson meta "$(cat "$meta_temp")" \
  --slurpfile entitlements $entitlements_temp \
  '$meta + {entitlements: $entitlements}' \
  | jq . > "$save_path"

rm "$entitlements_temp" "$meta_temp"

echo "All entitlements saved to: $save_path"