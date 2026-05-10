#!/bin/bash

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[ "$tool_name" = "Bash" ] || exit 0

# Check if command starts with git (trim leading whitespace)
trimmed=$(echo "$command" | sed 's/^[[:space:]]*//')
[[ "$trimmed" == git\ * || "$trimmed" == "git" ]] || exit 0

# Walk up from cwd looking for .jj directory
dir="$PWD"
in_jj=0
while [[ "$dir" != "/" ]]; do
  if [[ -d "$dir/.jj" ]]; then
    in_jj=1
    break
  fi
  dir=$(dirname "$dir")
done

[ "$in_jj" -eq 1 ] || exit 0

echo "Git command blocked: this repo uses Jujutsu (jj). Use jj instead of git. Load the /jujutsu skill for guidance on equivalent commands."
exit 2
