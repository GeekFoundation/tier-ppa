# Releasing

How to publish a new Tier release to the Geek Foundation PPA.

## How it works

This repo does not fork or mirror Tier. It holds only the Debian packaging
(`debian/`) and a gated GitHub Actions workflow that references an upstream tag,
builds a source package, and uploads it to Launchpad. Launchpad's build farm
compiles the binary `.deb` per series/arch and publishes it to the apt
repository.

**Flow:**

1. Tier publishes a release tag, e.g. `v0.8.0`.
2. Run the publish workflow (see below). The `build` job checks out that exact
   tag with its vendored submodules, overlays `debian/`, and builds an unsigned
   source package.
3. The `publish` job pauses for human approval on the `ppa-publish` environment.
   After approval it signs the source package and uploads it with `dput`.
4. Launchpad builds the binary and publishes it. Build status:
   ```bash
   make check-builds
   ```

The signing key stays behind the approval gate intentionally: an ungated job
that signs would produce a signed source package uploadable from anywhere.

**Package version** is `<upstream>~<series><revision>`, e.g. `0.8.0~noble1`.
The binary reports the clean upstream version (`0.8.0`).

**Upgrade behaviour:** on upgrade, `preinst` records whether the daemon was
running; `postinst` restarts it only if that flag is present. A running node
picks up the new binary automatically; a deliberately stopped node stays stopped.

## Publishing a release

```bash
make publish             # publish latest upstream tag, revision 1
make publish-dry         # same, but skip dput (exercises signing path)
make publish REVISION=2  # re-upload the same upstream version (packaging fix)
```

Requires `gh` (GitHub CLI) authenticated with access to this repo.

After triggering, approve the `ppa-publish` environment gate in GitHub Actions,
then monitor the Launchpad build with `make check-builds`.

## One-time setup

### Launchpad

1. Each uploader creates a Launchpad account at <https://launchpad.net>.
2. Generate a GPG key for signing uploads, publish it to `keyserver.ubuntu.com`
   (`gpg --send-keys <fpr>`), add the fingerprint to your Launchpad account, and
   confirm the email Launchpad sends.
3. Sign the Ubuntu Code of Conduct on Launchpad with that GPG key — required
   before any PPA upload.
4. Create a Launchpad team `geekfoundation` and add uploaders as members.
5. Create the PPA under the team: `ppa:geekfoundation/tier`.

### GitHub

6. Add repo **Secrets** (Settings → Secrets and variables → Actions):
   - `GPG_PRIVATE_KEY` — `gpg --armor --export-secret-keys <fpr>`
   - `GPG_PASSPHRASE` — the key's passphrase
   - `GPG_KEY_ID` — the key fingerprint
7. Create an **Environment** named `ppa-publish` (Settings → Environments) and
   add required reviewers.

## Local packaging check

To validate packaging changes before pushing, overlay `debian/` onto a Tier
checkout at the target tag (with submodules) and build the source package:

```bash
# from this repo root, with PPA_DIR=$(pwd):
cp -a debian /path/to/tier-core/
"$PPA_DIR"/scripts/make-changelog.sh 0.8.0 noble 1 /path/to/tier-core
cd /path/to/tier-core && debuild -S -us -uc -d
```

The binary build happens on Launchpad in a no-network clean chroot — submodules
must be present in the checkout (`submodules: recursive` in the workflow).

## Repo structure

| Path | Purpose |
|---|---|
| `debian/` | Source package: control, rules, copyright, maintainer scripts |
| `scripts/make-changelog.sh` | Generates `debian/changelog` per upload |
| `scripts/trigger-publish.sh` | Triggers the publish workflow via `gh` |
| `scripts/check-builds.sh` | Queries Launchpad build status |
| `scripts/install.sh` | End-user install script |
| `.github/workflows/publish-ppa.yml` | Gated publish workflow |
| `Makefile` | Task runner for maintainer scripts |
