# Security Policy

## Reporting a vulnerability

Please do **not** open a public issue for security problems. Use GitHub's
[private vulnerability reporting](../../security/advisories/new) for this repository
instead. You can expect an initial response within 7 days.

## Security review notes

- Safe rollout: firewall allows SSH before enabling default-deny; sshd config is
  validated (`sshd -t`) before restart; lock-out check for key-only SSH.
- Least privilege: config files get explicit owner/group/mode, sensitive ones
  restrictive modes (sshd drop-in and nftables ruleset `0600`, audit rules `0640`).
- No credentials in the repository; real inventories are git-ignored.
- CI: yamllint, ansible-lint (production profile), Molecule and gitleaks; GitHub
  Actions pinned to commit SHAs with `contents: read` permissions.
