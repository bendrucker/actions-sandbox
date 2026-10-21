#!/bin/sh
# One-job spike: start bin/actions-sandbox on this repo, dispatch spike.yml, and
# print the run's log. All output goes to the log file only, so the terminal
# stays quiet until it exits.
set -eu

REPO=bendrucker/actions-sandbox
LOG=$HOME/tmp/actions-sandbox-spike.log
here=$(cd "$(dirname "$0")" && pwd)

mkdir -p "$(dirname "$LOG")"
exec > "$LOG" 2>&1

command -v container >/dev/null || { echo "container is not installed: brew install container"; exit 1; }

ACTIONS_SANDBOX_REPO=$REPO "$here/../bin/actions-sandbox" &
runner=$!
sleep 15
gh workflow run spike.yml -R "$REPO"
wait "$runner" || echo "runner exit=$?"

sleep 5
id=$(gh run list -R "$REPO" -w spike.yml -L 1 --json databaseId --jq '.[0].databaseId')
gh run view "$id" -R "$REPO" --log || gh run view "$id" -R "$REPO"
echo "done"
