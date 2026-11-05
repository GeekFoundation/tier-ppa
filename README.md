# tier-ppa

Geek Foundation packaging and delivery for [Tier](https://github.com/tier-org/tier-core).

Tier develops the code and cuts releases (git tags `vX.Y.Z`). **This repo does
not fork or mirror Tier.** It holds only the Debian packaging (`debian/`) and a
"click to publish" workflow that references a Tier tag, builds a source package,
and uploads it to the Geek Foundation PPA on Launchpad. Launchpad's build farm
compiles the `.deb` per Ubuntu series/arch and signs the apt repository.

Because we reference a tag instead of forking, there is never a merge and never
a conflict with Tier development.

## How a release reaches the PPA

1. Tier publishes a release, e.g. tag `v0.5.0`.
2. A Geek Foundation engineer opens **Actions -> publish-ppa -> Run workflow**,
   enters the tag (`v0.5.0`) and the target series (`noble`), and runs it.
   Ubuntu 24.04 (noble) is the supported series: it is the only one whose
   archive cmake (3.28) satisfies tier-core's `cmake_minimum_required(3.25)`.
3. The `build` job checks out that exact Tier tag with its vendored submodules
   (`vendor/openssl`, `vendor/ngtcp2`), overlays `debian/`, and builds an
   **unsigned source package**.
4. The `publish` job **waits for approval** on the `ppa-publish` environment. A
   second person approves; only then is the source package signed and uploaded
   with `dput`. A `dry_run` goes through the same gate and the same signing, and
   skips only the upload — so the signing path is proven before a real release.
   The key stays behind the gate on purpose: a job that signs without approval
   would hand out a signed source package, and that is uploadable from anywhere.
5. Launchpad builds the binary `.deb` and publishes it. Watch the build on the
   PPA page.

On a fresh install the package enables `tierd` for boot but does not start it
(the operator edits `/etc/tier/tierd.toml` first). On an **upgrade**, `preinst`
records whether the unit was active and then `dh_installsystemd --no-start`
stops it; `postinst` restarts it only if that flag is present. So a running node
picks up the new binary — which is what makes `unattended-upgrades` on this PPA
meaningful — while a node the operator deliberately stopped stays stopped.

To re-upload the **same** Tier version (e.g. a packaging-only fix), rerun with
the same tag and a higher **revision** (Launchpad rejects an identical version).
Package version is `<upstream>~<series><revision>`, e.g. `0.5.0~noble1`; the
binary still reports the clean upstream version (`0.5.0`).

## One-time setup (human, do this before the first run)

**Launchpad**
1. Each uploader creates a Launchpad account (<https://launchpad.net>).
2. Generate a GPG key for signing uploads, publish it
   (`gpg --send-keys <fpr>` to `keyserver.ubuntu.com`), add the fingerprint to
   your Launchpad account, and confirm the email Launchpad sends.
3. Sign the Ubuntu Code of Conduct on Launchpad with that GPG key. **Required**
   before any PPA upload.
4. Create a Launchpad **team** `geekfoundation` (owned by the Foundation) and
   add uploaders as members.
5. Create the PPA under the team: `ppa:geekfoundation/tier`. Confirm the
   `owner/name` matches the workflow's `ppa` input default.

**GitHub**
6. Create this repo under the Foundation org (e.g. `geekfoundation/tier-ppa`)
   and push this tree.
7. Add repo **Secrets** (Settings -> Secrets and variables -> Actions):
   - `GPG_PRIVATE_KEY` - armored export of the signing key
     (`gpg --armor --export-secret-keys <fpr>`).
   - `GPG_PASSPHRASE` - its passphrase.
   - `GPG_KEY_ID` - the key fingerprint.
8. Create an **Environment** named `ppa-publish` (Settings -> Environments) and
   add **required reviewers**. This is the approval gate before upload.
9. Set the real maintainer identity: edit `debian/control` `Maintainer:` and the
   `DEBFULLNAME`/`DEBEMAIL` in `.github/workflows/publish-ppa.yml` to the
   Foundation's address.

Users then install with:

```
sudo add-apt-repository ppa:geekfoundation/tier
sudo apt update && sudo apt install tierd
```

## Local check (optional, before pushing packaging changes)

With a Tier checkout at a tag that has its submodules, overlay `debian/` and
build the source package to validate the packaging:

```
# from this repo, with PPA_DIR=$(pwd):
cp -a debian /path/to/tier-core/ && cd /path/to/tier-core
"$PPA_DIR"/scripts/make-changelog.sh 0.5.0 noble 1 .   # or hand-write debian/changelog
debuild -S -us -uc -d
```

The real binary build happens on Launchpad; its no-network, clean-chroot build
is why the submodules must be present in the checkout (the workflow uses
`submodules: recursive`).

## What lives where

- `debian/` - the source package (control, rules, copyright, maintainer script,
  source format). The upstream CMake owns the install layout; `debian/rules`
  only drives it with release flags and lets debhelper package the result.
- `scripts/make-changelog.sh` - generates `debian/changelog` per upload.
- `.github/workflows/publish-ppa.yml` - the gated publish workflow.
