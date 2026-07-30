# Shuttle

[![Join the chat at https://gitter.im/fitztrev/shuttle](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/fitztrev/shuttle?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A simple shortcut menu for macOS

[http://fitztrev.github.io/shuttle/](http://fitztrev.github.io/shuttle/)

**Fork note**: *This is a fork of [fitztrev/shuttle](https://github.com/fitztrev/shuttle). It builds as a universal binary that runs natively on Apple Silicon, replaces the unreliable `LSSharedFileList` login-item backend with a `launchd` LaunchAgent, and fixes menu entries failing with "The application can't be opened." on current macOS. No binaries are published here, build it from source.*

![How Shuttle works](https://raw.githubusercontent.com/fitztrev/shuttle/gh-pages/images/how-shuttle-works.gif)

**Sidenote**: *Many people ask, so here's how I have [my terminal setup](https://github.com/fitztrev/shuttle/wiki/My-Terminal-Prompt).*

## Installation

This fork publishes no releases. Build it yourself with the steps below, then copy `build/Release/Shuttle.app` to `/Applications`.

The [upstream download](http://fitztrev.github.io/shuttle/) is still available, but it ships version 1.2.9 as x86_64 only, so it runs under Rosetta on Apple Silicon and does not reliably start at login. Those are the two things this fork exists to fix.

## Building from source

Requires Xcode. From the repository root:

```sh
xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Release \
  SYMROOT=build ONLY_ACTIVE_ARCH=NO build
```

The app lands in `build/Release/Shuttle.app` and runs natively on Apple Silicon, no Rosetta involved. Xcode ad-hoc signs it automatically, so no Apple Developer account and no notarization are needed to build and run your own copy.

Both overrides matter:

* `SYMROOT=build` puts the product in `build/Release/`. Without it the product goes to a DerivedData path, which is easy to miss and leaves any older copy in `build/` looking current.
* `ONLY_ACTIVE_ARCH=NO` produces a universal binary. The project already sets this, but `xcodebuild` builds only the active architecture for a scheme-based `build` action unless you override it here, which quietly yields an arm64-only binary.

The build prints `Shuttle isn't code signed but requires entitlements`. That is expected and harmless: `Shuttle.entitlements` only requests a sandbox exception for Apple Events, and Shuttle is not sandboxed. The Automation permission prompt comes from `NSAppleEventsUsageDescription` in the Info.plist, which is unaffected.

The deployment target is macOS 11.0. Two things force that floor: arm64 macOS starts at 11.0, so no universal build can target lower, and the x86_64 slice fails to link below 10.11 anyway because current Xcode no longer ships the `libarclite` ARC compatibility library.

## Launch at login

Setting `"launch_at_login": true` in your config registers Shuttle with `launchd` by writing `~/Library/LaunchAgents/shuttle.Shuttle.LaunchAtLogin.plist`. It takes effect at your next login. Setting it back to `false` unloads and removes the agent.

Editing the config is not enough on its own: Shuttle only re-reads it when you open the menu. So after changing this key, click the menu bar icon once to apply it. This is how every Shuttle setting works, but it is easy to miss here because the effect is a file on disk rather than a visible change in the menu. You can confirm the current state with `ls ~/Library/LaunchAgents/shuttle.Shuttle.LaunchAtLogin.plist`.

This replaces the old `LSSharedFileList` implementation, deprecated in macOS 10.11 and marked "no longer supported" in the system headers. In testing it proved unreliable rather than uniformly broken: a fresh build of the old code did register successfully on macOS 26, while the shipped 1.2.9 release did not register at all on a current system even with the key set to `true`. A mechanism that depends on which binary you happen to be running is not worth keeping.

`SMAppService` would be the modern API, but it requires a Team ID and does not accept an ad-hoc signature, so it is unusable in a build anyone can produce for free. A plain LaunchAgent carries no signing requirement and is a readable file you can inspect with `launchctl print gui/$(id -u)/shuttle.Shuttle.LaunchAtLogin`.

**Upgrading**: if a previous version already registered Shuttle the old way, that entry is independent of the new agent and will start a second copy at login. Remove it once under System Settings → General → Login Items & Extensions.

## Help
See the [Wiki](https://github.com/fitztrev/shuttle/wiki) pages. 

## Roadmap

* Cloud hosting integration
  * AWS, Rackspace, Digital Ocean, etc
  * Using their APIs, automatically add all of your machines to the menu
* Preferences panel for easier configuration
* Update notifications
* Keyboard hotkeys
  * Open menu
  * Select host option within menu

## Contributors

This project was created by [Trevor Fitzgerald](https://github.com/fitztrev). I owe many thanks to the following people who have helped make Shuttle even better.

(In alphabetical order)

* [Alexis NIVON](https://github.com/anivon)
* [Alex Carter](https://github.com/blazeworx)
* [bihicheng](https://github.com/bihicheng)
* [Dave Eddy](https://github.com/bahamas10)
* [Dmitry Filimonov](https://github.com/petethepig)
* [Frank Enderle](https://github.com/fenderle)
* [Jack Weeden](https://github.com/jackbot)
* [Justin Swanson](https://github.com/geeksunny)
* [Kees Fransen](https://github.com/keesfransen)
* Marco Aurélio
* [Martin Grund](https://github.com/grundprinzip)
* [Matt Turner](https://github.com/thshdw)
* [Michael Davis](https://github.com/mpdavis)
* [Morton Fox](https://github.com/mortonfox)
* [Pluwen](https://github.com/pluwen)
* Rebecca Dominguez
* [Rui Rodrigues](https://github.com/rmrodrigues)
* [Ryan Cohen](https://github.com/imryan)
* [Stefan Jansen](https://github.com/steffex)
* Thomas Rosenstein
* [Thoro](https://github.com/Thoro)
* [Tibor Bödecs](https://github.com/tib)
* [welsonla](https://github.com/welsonla)

## Credits

Shuttle was inspired by [SSHMenu](http://sshmenu.sourceforge.net/), the GNOME applet for Linux.

I also looked to projects such as [MLBMenu](https://github.com/markolson/MLB-Menu) and [QuickSmileText](https://github.com/scturtle/QuickSmileText) for direction on building a Cocoa app for the status bar.
