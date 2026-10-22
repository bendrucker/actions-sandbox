# actions-sandbox

A self-hosted GitHub Actions runner that runs each job in a throwaway Linux VM on macOS. Each runner is just-in-time: GitHub's [runner image](https://github.com/actions/runner/pkgs/container/actions-runner) starts under Apple's [container](https://github.com/apple/container) tool, takes one job, and exits with its VM. The job sees only what the launcher mounts into it, never the host's home directory.

`bin/actions-sandbox` runs one job and exits. Run it under a supervisor that restarts it, such as a launchd agent with `KeepAlive`, so one runner is always waiting. It reads its config from the environment:

| Variable | Meaning |
| --- | --- |
| `ACTIONS_SANDBOX_REPO` | `owner/repo` the runner registers on (required) |
| `ACTIONS_SANDBOX_LABELS` | Comma-separated labels beside `self-hosted` (default `actions-sandbox`) |
| `ACTIONS_SANDBOX_MOUNTS` | Newline-separated `container run --volume` specs, the only host paths a job sees |
| `ACTIONS_SANDBOX_CPUS` | VM CPUs (default `8`) |
| `ACTIONS_SANDBOX_MEMORY` | VM memory (default `16G`; `container`'s own 1G default starves most jobs) |

It needs macOS 26 or later, Apple's `container` (`brew install container`), and an authenticated `gh` that can register runners on the repo. Jobs get full network access.

`spike/run.sh` runs one job on this repo through `bin/actions-sandbox` and checks that it can reach GitHub but not the host's files.
