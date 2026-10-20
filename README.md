# actions-sandbox

A self-hosted GitHub Actions runner whose jobs run inside [Anthropic's sandbox runtime](https://github.com/anthropic-experimental/sandbox-runtime) (`srt`). Each runner is just-in-time: it takes one job and exits, and every step of that job inherits the sandbox's filesystem and network policy.

Status: spike. `spike/run.sh` registers one runner on this repo, dispatches `spike.yml`, and checks that the sandbox allows what a job needs and denies the rest.
