# tier-ppa

Ubuntu packages for [Tier](https://github.com/tier-org/tier-core), distributed
via the [Geek Foundation PPA](https://launchpad.net/~geekfoundation/+archive/ubuntu/tier).

Requires Ubuntu 24.04 (noble).

## Install

The install script adds the PPA, installs `tierd`, and copies a node config
preset to `/etc/tier/tierd.toml`. It is idempotent — re-running skips steps
that are already done and never overwrites an existing config.

**Client node:**

```bash
curl -fsSL https://raw.githubusercontent.com/GeekFoundation/tier-ppa/main/scripts/install.sh | sudo bash
```

**Client node with automatic updates:**

```bash
curl -fsSL https://raw.githubusercontent.com/GeekFoundation/tier-ppa/main/scripts/install.sh | sudo bash -s -- --unattended-upgrade
```

**Validator node:**

```bash
curl -fsSL https://raw.githubusercontent.com/GeekFoundation/tier-ppa/main/scripts/install.sh | sudo bash -s -- --preset=validator
```

**Validator node with automatic updates:**

```bash
curl -fsSL https://raw.githubusercontent.com/GeekFoundation/tier-ppa/main/scripts/install.sh | sudo bash -s -- --preset=validator --unattended-upgrade
```

After installation, review `/etc/tier/tierd.toml` if needed, then start the daemon:

```bash
sudo systemctl start tierd
```

## Uninstall

Remove the package (keeps config files):

```bash
sudo apt remove tierd
```

Remove the package and purge all config:

```bash
sudo apt purge tierd && sudo rm -rf /etc/tier
sudo add-apt-repository --remove ppa:geekfoundation/tier
```

Disable automatic updates only:

```bash
sudo rm -f /etc/apt/apt.conf.d/51geekfoundation-tier
```

## Automatic updates

When installed with `--unattended-upgrade`, Ubuntu's `unattended-upgrades`
checks for new versions once a day and upgrades automatically. A running node
restarts on the new binary; a node that was stopped stays stopped.

---

For information on publishing new releases to the PPA, see [RELEASING.md](RELEASING.md).
