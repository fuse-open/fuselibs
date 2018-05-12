# Fuselibs
[![Tracis CI Build Status](https://travis-ci.org/fusetools/fuselibs-public.svg?branch=master)](https://travis-ci.org/fusetools/fuselibs-public)
[![AppVeyor Build status](https://ci.appveyor.com/api/projects/status/an47qhe561v31jga/branch/master?svg=true)](https://ci.appveyor.com/project/fusetools/fuselibs-public/branch/master)
[![license: MIT](https://img.shields.io/github/license/fusetools/fuselibs-public.svg)](LICENSE.txt)
[![Slack](https://img.shields.io/badge/chat-on%20slack-blue.svg)](https://fusecommunity.slack.com/messages/fuselibs)

Fuselibs is the [Uno](https://www.fusetools.com/docs/uno/uno-lang)-libraries that provide
the UI framework used in [Fuse](https://www.fusetools.com/) apps.


## Requirements

In order to use Uno / Fuselibs, the following software must be installed:

### Windows

* VCRedist 2010: [x86](https://www.microsoft.com/en-us/download/details.aspx?id=5555), [x64](https://www.microsoft.com/en-US/Download/confirmation.aspx?id=14632)
* [VCRedist 2013](https://www.microsoft.com/en-gb/download/details.aspx?id=40784)

### macOS

* [Mono 5.4.1](https://download.mono-project.com/archive/5.4.1/macos-10-universal/MonoFramework-MDK-5.4.1.7.macos10.xamarin.universal.pkg)
* [XCode](https://developer.apple.com/xcode/)
* [CMake](https://cmake.org/)


## How do I build and test?

### Windows

* `build.bat` downloads and extracts uno, and builds all packages.
* `test.bat` runs all tests.

### macOS

* `build.sh` downloads and extracts uno, and builds all packages.
* `test.sh` runs all tests.


### Fuse

You may use a locally built copy of fuselibs with an installed copy of
Fuse. This is done by creating a file named `.unoconfig` in either a Fuse
project directory (applies to that project only), or in your home
directory (applies to all projects). It should contain something like the
following:

```
Packages.SourcePaths += <path-to-fuselibs>/Source
```

You'll need to replace `<path-to-fuselibs>` above with the actual path to
your fuselibs checkout.


## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of
conduct, and the process for submitting pull requests to us.

### Reporting issues

Please report issues [here](https://github.com/fusetools/fuselibs-public/issues).

## What's this "Stuff" thing?

Stuff is the tool that downloads and extracts `uno` (which is required to
build fuselibs), as well as some other useful utilities. The `Stuff`
directory contains `stuff.exe`, a few `.stuff`-files and a few
`.packages`-files. `stuff.exe` is a tool that reads the `.stuff`-files,
and download and extract them into the source tree. The dependencies
specified in the `.package`-files installed lazily by `uno doctor` when
needed. This is all automated in `build.bat` and `build.sh`.

After `stuff.exe` has done it's job, you can find:

| Component                      | Path           |
|:-------------------------------|:---------------|
| Prebuilt uno wrapper (Windows) | Stuff/uno.exe  |
| Prebuilt uno wrapper (macOS)   | Stuff/uno      |
| Prebuilt core packages         | Stuff/lib      |
| Development tools              | Stuff/Devtools |
