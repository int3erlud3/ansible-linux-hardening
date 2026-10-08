# ansible-linux-hardening

[![CI](https://github.com/OWNER/ansible-linux-hardening/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/ansible-linux-hardening/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An Ansible role (`linux_hardening`) and example playbook that apply a pragmatic
security baseline to **Debian 12/13 and Ubuntu 22.04/24.04** servers. Every part can
be toggled and tuned through variables; the role is idempotent and tested with
Molecule.

## What it does

| Area | Details |
|---|---|
| **SSH** | Drop-in `sshd_config.d/00-hardening.conf`: key-only auth, no root login, modern KEX/ciphers/MACs, `MaxAuthTries 3`, no X11/agent/TCP forwarding, verbose logging, optional `AllowGroups`. Validated with `sshd -t` before restart |
| **Firewall** | `ufw` (default) or `nftables`: default deny inbound, SSH always allowed (with rate limiting), extra TCP/UDP ports via variables |
| **fail2ban** | `sshd` jail (systemd backend, aggressive mode) using the matching ufw/nftables ban action |
| **Updates** | `unattended-upgrades` for security updates, optional automatic reboot and mail report |
| **Kernel** | `sysctl` hardening (rp_filter, no redirects/source routing, syncookies, kptr/dmesg restrictions, ptrace scope, protected links, …) |
| **Auditing** | `auditd` with rules for identity files, sudoers, SSH config, time changes, kernel modules, privileged commands; optional immutable mode |

## Requirements

- Ansible ≥ 2.15 (tested with ansible-core 2.21)
- Collections: `ansible.posix`, `community.general` (`ansible-galaxy collection install -r requirements.yml`)
- Target: Debian/Ubuntu with Python 3, SSH access with a key and `sudo`

## Usage

```bash
git clone https://github.com/OWNER/ansible-linux-hardening.git
cd ansible-linux-hardening
ansible-galaxy collection install -r requirements.yml
cp inventory/hosts.example.yml inventory/hosts.yml   # edit hosts and variables

# Always preview first
ansible-playbook playbooks/site.yml --check --diff

ansible-playbook playbooks/site.yml
ansible-playbook playbooks/site.yml --tags ssh,firewall   # only some areas
```

Use the role in your own playbook:

```yaml
- hosts: webservers
  become: true
  roles:
    - role: linux_hardening
      vars:
        linux_hardening_firewall_allowed_tcp_ports: [80, 443]
        linux_hardening_ssh_allow_groups: [sudo, ssh-users]
```

## Key variables

See [`roles/linux_hardening/defaults/main.yml`](roles/linux_hardening/defaults/main.yml)
for all options (validated by `meta/argument_specs.yml`).

| Variable | Default | Description |
|---|---|---|
| `linux_hardening_{ssh,firewall,fail2ban,unattended_upgrades,sysctl,auditd}_enabled` | `true` | Toggle each area |
| `linux_hardening_ssh_port` | `22` | SSH port (always allowed in the firewall) |
| `linux_hardening_ssh_permit_root_login` | `"no"` | `no` or `prohibit-password` |
| `linux_hardening_ssh_password_authentication` | `false` | Allow password logins |
| `linux_hardening_ssh_allow_groups` | `[]` | Restrict SSH to these groups |
| `linux_hardening_ssh_lockout_check` | `true` | Abort if the connecting user has no `authorized_keys` |
| `linux_hardening_firewall_backend` | `ufw` | `ufw` or `nftables` |
| `linux_hardening_firewall_allowed_tcp_ports` / `_udp_ports` | `[]` | Additional inbound ports |
| `linux_hardening_fail2ban_bantime` / `_findtime` / `_maxretry` | `1h` / `10m` / `5` | fail2ban settings |
| `linux_hardening_unattended_upgrades_reboot` | `false` | Automatic reboot after updates |
| `linux_hardening_sysctl_extra` | `{}` | Additional/overriding sysctl keys |
| `linux_hardening_auditd_immutable` | `false` | Lock audit rules until reboot |

## Testing

```bash
pip install -r requirements-dev.txt
make lint syntax   # yamllint --strict, ansible-lint (production profile), syntax check
make molecule      # converge + idempotence + verify on Debian 12 and Ubuntu 24.04 (Docker)
```

In containers the role detects `virtualization_type` and skips only what a container
cannot do (loading sysctl values, enabling the firewall, starting auditd, restarting
services); all configuration files are still rendered, validated and verified.

## Security notes

- **Lock-out protection**: SSH is allowed in the firewall *before* the default-deny
  policy is enabled, `sshd -t` validates every change before the restart, and the
  role refuses to disable password logins when the connecting user (`ansible_user`)
  has no `authorized_keys` file.
- Test on a non-production host first and keep a console/out-of-band session open
  when hardening remote machines.
- No secrets are needed or stored; the inventory example uses documentation IPs and
  the real inventory (`inventory/hosts.yml`) is git-ignored.
- `ansible-lint` runs with the strictest (`production`) profile; all file tasks set
  explicit owner/group/mode.

See [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
