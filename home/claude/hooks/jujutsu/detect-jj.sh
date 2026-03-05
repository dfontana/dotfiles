#!/bin/bash

# Skip if jj is not installed
if ! command -v jj >/dev/null 2>&1; then
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
  exit 0
fi

# Skip if the working directory is not a jj workspace
if ! jj workspace root >/dev/null 2>&1; then
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
  exit 0
fi

# This is a jj workspace — tell Claude to load the jujutsu skill
echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This repository uses Jujutsu (jj) for version control. Load the jujutsu skill immediately and follow its workflow rules for all version control operations."}}'
exit 0
