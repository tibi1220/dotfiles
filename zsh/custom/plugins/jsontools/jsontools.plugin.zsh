#!/usr/bin/env zsh

# ------------------------------------------------------------------------------
# (Copied from OMZ)
# (https://github.com/ohmyzsh/ohmyzsh/)
# ------------------------------------------------------------------------------
#
# JSON Tools
# Adds command line aliases useful for dealing with JSON

# Define json tools for node
function pp_json() {
  xargs -0 node -e 'console.log(JSON.stringify(JSON.parse(process.argv[1]), null, 4));'
}
function is_json() {
  xargs -0 node -e '
        try {
          json = JSON.parse(process.argv[1]);
          console.log("true");
          process.exit(0);
        } catch (e) {
          console.log("false");
          process.exit(1);
        }
      '
}
function urlencode_json() {
  xargs -0 node -e "console.log(encodeURIComponent(process.argv[1]))"
}
function urldecode_json() {
  xargs -0 node -e "console.log(decodeURIComponent(process.argv[1]))"
}

# Add NDJSON support
function {pp,is,urlencode,urldecode}_ndjson() {
  local json jsonfunc="${0//ndjson/json}"
  while read -r json; do
    $jsonfunc <<<"$json"
  done
}
