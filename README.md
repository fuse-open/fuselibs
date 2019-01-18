# Fuselibs
[![Travis CI Build Status](https://travis-ci.org/fuse-open/fuselibs.svg?branch=master)](https://travis-ci.org/fuse-open/fuselibs)
[![AppVeyor Build status](https://ci.appveyor.com/api/projects/status/an47qhe561v31jga/branch/master?svg=true)](https://ci.appveyor.com/project/fusetools/fuselibs-public/branch/master)
[![license: MIT](https://img.shields.io/github/license/fuse-open/fuselibs.svg)](LICENSE.txt)
[![Slack](https://img.shields.io/badge/chat-on%20slack-blue.svg)](https://slackcommunity.fusetools.com/)

Fuselibs is a collection of [Uno](https://fuseopen.com/docs/uno/uno-lang) libraries that provide
the UI framework used to build [Fuse](https://fuseopen.com/) apps.


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

```
npm install
npm run build
npm run test
```

You can run the local `uno` directly using `node_modules/.bin/uno`. This
is useful when you want to test apps using your local fuselibs build
environment.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of
conduct, and the process for submitting pull requests to us.

### Reporting issues

Please report issues [here](https://github.com/fuse-open/fuselibs/issues).
