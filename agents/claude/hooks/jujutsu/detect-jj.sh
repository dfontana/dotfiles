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

# This is a jj workspace. Inject the everyday rules directly rather than
# telling Claude to load the jujutsu skill: loading a skill at session start
# attributes every following turn in the session to that skill. The skill is
# reference material and should be pulled in only when actually needed.
echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This repository uses Jujutsu (jj), confirmed by jj workspace root. Do not use raw git for commits, history, or diffs. Before writing code, run `jj diff -r @` and stop if it is non-empty; then run `jj describe -m \"<intent>\"`. Load the jujutsu skill only for squashing, stacked pull requests, conflict resolution, or jj syntax you are unsure of."}}'
exit 0
