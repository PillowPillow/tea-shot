# Security policy

## Supported versions

Only the latest release receives security fixes.

## Reporting a vulnerability

Please do not open a public issue. Report it privately through [GitHub's private vulnerability reporting](https://github.com/PillowPillow/tea-shot/security/advisories/new) instead, with the steps to reproduce and the impact you see.

You can expect a first answer within a week. Once a fix is released, the advisory is published with credit to you unless you prefer otherwise.

## Scope

- The TeaShot app.
- `install.sh` and the release workflow that builds the published zip.

To check that a release zip was built by this repository's release workflow, run `gh attestation verify TeaShot.zip --repo PillowPillow/tea-shot --signer-workflow PillowPillow/tea-shot/.github/workflows/release.yml` with the GitHub CLI signed in.
