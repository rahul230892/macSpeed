# NetSpeed

NetSpeed is a small macOS menu bar utility that displays live upload and
download throughput. It supports launch at login and secure in-app updates.

## Requirements

- macOS Sonoma 14 or newer
- Apple silicon or Intel Mac
- [Homebrew](https://brew.sh)

## Install

```bash
brew install --cask rahul230892/tap/netspeed
```

Homebrew installs NetSpeed in `/Applications`. Launch it once from Spotlight or
the Applications folder; its live speed indicator then appears in the menu bar.

## Update

NetSpeed checks for updates automatically. You can also select **Check for
Updates…** from its menu at any time.

Homebrew remains available as a fallback:

```bash
brew upgrade --cask netspeed
```

## Uninstall

Remove the application but retain preferences:

```bash
brew uninstall --cask netspeed
```

Remove the application and all NetSpeed preferences:

```bash
brew uninstall --cask --zap netspeed
```

## Privacy

NetSpeed reads the byte counters maintained by macOS for active network
interfaces. It does not inspect packet contents, store browsing activity, or
send network statistics to a server. Network access is used only to retrieve
the signed update feed and update archives from GitHub.

## Development

Open `NetSpeed.xcodeproj` in Xcode. The application targets macOS 14 and uses
Sparkle 2.9.6 through Swift Package Manager.

Build a universal local release:

```bash
./build.sh 1.2.0 2
```

The app and update ZIP are written to `dist/`.

## Creating a release

The release script requires a clean Git working tree, GitHub CLI authentication,
the Homebrew tap at `/opt/homebrew/Library/Taps/rahul230892/homebrew-tap`, and the
NetSpeed Sparkle signing key in the login Keychain.

```bash
./release.sh 1.2.0 2
```

It builds and verifies a universal app, signs the update with Sparkle, publishes
`NetSpeed.zip` and `appcast.xml` to GitHub Releases, and updates the Homebrew
cask. Increase both the semantic version and numeric build number for every
release.

### Update-signing key backup

The private Sparkle key is stored in the login Keychain under the account
`com.rahul.NetSpeed`. Back it up in a secure password manager; never commit it.
With Sparkle's tools available, export it using:

```bash
generate_keys --account com.rahul.NetSpeed -x NetSpeed-sparkle-private-key
```

Delete the exported file immediately after placing it in secure storage.

## Distribution note

NetSpeed is not Apple-notarized. The Homebrew cask removes quarantine only from
the installed NetSpeed bundle so users do not receive an unidentified-developer
dialog. In-app update archives are independently authenticated with Sparkle's
Ed25519 signatures. The GitHub repository, Homebrew tap, and Sparkle signing key
must therefore be protected with strong credentials and two-factor
authentication.

