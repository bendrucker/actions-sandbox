#!/bin/sh
# One-job spike: register a just-in-time runner on this repo, start GitHub's
# runner image in a throwaway Linux VM with Apple's container tool, dispatch
# spike.yml, and print the run's log. All output goes to the log file only, so
# the terminal stays quiet until it exits.
set -eu

REPO=bendrucker/actions-sandbox
LOG=$HOME/tmp/actions-sandbox-spike.log

mkdir -p "$(dirname "$LOG")"
exec > "$LOG" 2>&1

command -v container >/dev/null || { echo "container is not installed: brew install container"; exit 1; }
container system status >/dev/null 2>&1 || container system start --enable-kernel-install

version=$(gh api repos/actions/runner/releases/latest --jq .tag_name | sed 's/^v//')
image=ghcr.io/actions/actions-runner:$version
name=spike-$(date +%s)
echo "image $image, runner $name"

jit=$(gh api -X POST "repos/$REPO/actions/runners/generate-jitconfig" \
  -f name="$name" -F runner_group_id=1 -f work_folder=_work \
  -f 'labels[]=self-hosted' -f 'labels[]=actions-sandbox' --jq .encoded_jit_config)

container run --rm --name "$name" "$image" ./run.sh --jitconfig "$jit" &
runner=$!
sleep 15
gh workflow run spike.yml -R "$REPO"
wait "$runner" || echo "runner exit=$?"

sleep 5
id=$(gh run list -R "$REPO" -w spike.yml -L 1 --json databaseId --jq '.[0].databaseId')
gh run view "$id" -R "$REPO" --log || gh run view "$id" -R "$REPO"
echo "done"
