#!/bin/sh
# One-job spike: register a just-in-time runner on this repo, start it under
# srt, dispatch spike.yml, and print the run's log. All output goes to the log
# file only, so the terminal stays quiet until it exits.
set -eu

REPO=bendrucker/actions-sandbox
SRT=@anthropic-ai/sandbox-runtime@0.0.81
LOG=$HOME/tmp/actions-sandbox-spike.log
here=$(cd "$(dirname "$0")" && pwd)

# The runner exits unless it can list every ancestor of its root, and the
# policy denies reads under ~, so the work dir lives outside it.
DIR=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/actions-sandbox-spike.XXXXXX")" && pwd -P)
mkdir -p "$DIR/runner" "$(dirname "$LOG")"
exec > "$LOG" 2>&1

version=$(gh api repos/actions/runner/releases/latest --jq .tag_name | sed 's/^v//')
echo "runner $version, srt $SRT, dir $DIR"
curl -fsSL "https://github.com/actions/runner/releases/download/v$version/actions-runner-osx-arm64-$version.tar.gz" |
  tar -xz -C "$DIR/runner"

sed "s|@DIR@|$DIR|g" "$here/policy.json" > "$DIR/policy.json"

jit=$(gh api -X POST "repos/$REPO/actions/runners/generate-jitconfig" \
  -f name="spike-$(date +%s)" -F runner_group_id=1 -f work_folder=_work \
  -f 'labels[]=self-hosted' -f 'labels[]=actions-sandbox' --jq .encoded_jit_config)

npx -y "$SRT" --settings "$DIR/policy.json" -c "cd '$DIR/runner' && ./run.sh --jitconfig $jit" &
runner=$!

sleep 15
gh workflow run spike.yml -R "$REPO"
wait "$runner" || echo "runner exit=$?"

sleep 5
id=$(gh run list -R "$REPO" -w spike.yml -L 1 --json databaseId --jq '.[0].databaseId')
gh run view "$id" -R "$REPO" --log || gh run view "$id" -R "$REPO"
echo "done"
