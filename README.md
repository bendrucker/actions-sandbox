# actions-sandbox

A self-hosted GitHub Actions runner that runs each job in a throwaway Linux VM on macOS. Each runner is just-in-time: GitHub's [runner image](https://github.com/actions/runner/pkgs/container/actions-runner) starts under Apple's [container](https://github.com/apple/container) tool, takes one job, and exits with its VM. The job sees only what the launcher mounts into it, never the host's home directory.

Status: spike. `spike/run.sh` registers one runner on this repo, dispatches `spike.yml`, and checks that the job can reach GitHub but not the host's files.
