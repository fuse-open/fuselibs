# Fuselibs

[![AppVeyor build status](https://img.shields.io/appveyor/ci/fusetools/fuselibs-public/master.svg?logo=appveyor&logoColor=silver&style=flat-square)](https://ci.appveyor.com/project/fusetools/fuselibs-public/branch/master)
[![Travis CI build status](https://img.shields.io/travis/fuse-open/fuselibs/master.svg?style=flat-square)](https://travis-ci.org/fuse-open/fuselibs)
[![NPM package](https://img.shields.io/npm/v/@fuse-open/fuselibs.svg?style=flat-square)](https://www.npmjs.com/package/@fuse-open/fuselibs)
[![NPM package](https://img.shields.io/npm/v/@fuse-open/fuselibs/beta.svg?style=flat-square)](https://www.npmjs.com/package/@fuse-open/uno)
[![License: MIT](https://img.shields.io/github/license/fuse-open/fuselibs.svg?style=flat-square)](LICENSE.txt)
[![Slack](https://img.shields.io/badge/chat-on%20slack-blue.svg?style=flat-square)](https://slackcommunity.fusetools.com/)
[![Financial Contributors on Open Collective](https://opencollective.com/fuse-open/all/badge.svg?label=financial+contributors&style=flat-square)](https://opencollective.com/fuse-open)

![Target platforms](https://img.shields.io/badge/target%20os-Android%20%7C%20iOS%20%7C%20Linux%20%7C%20macOS%20%7C%20Windows-7F5AB6?style=flat-square&logo=android&logoColor=silver)
![Host platforms](https://img.shields.io/badge/host%20os-Linux%20%7C%20macOS%20%7C%20Windows-7F5AB6?style=flat-square)

> Build beautiful, high-performance iOS and Android apps with a single codebase.

Fuselibs is a collection of [Uno](https://fuseopen.com/docs/uno/uno-lang) libraries that provide
the UI framework used to build [Fuse](https://fuseopen.com/) apps.

## Install

```
$ npm install @fuse-open/fuselibs
```

### TypeScript definitions

* [@fuse-open/types](https://www.npmjs.com/package/@fuse-open/types)

### Related packages

* [android-build-tools](https://www.npmjs.com/package/android-build-tools)
* [fuse-sdk](https://www.npmjs.com/package/fuse-sdk)
* [uno](https://www.npmjs.com/package/@fuse-open/uno)

### Requirements

The following software must be installed in order to use Uno and Fuselibs.

#### Android

* Android SDK
* Android NDK
* Java JDK

> These dependencies can be acquired by installing [android-build-tools](https://www.npmjs.com/package/android-build-tools).

#### iOS

* [Xcode](https://developer.apple.com/xcode/)
* [ios-deploy](https://www.npmjs.com/package/ios-deploy)

#### macOS

* [Xcode](https://developer.apple.com/xcode/)
* [CMake](https://cmake.org/)

#### Windows

* [VCRedist 2010](https://www.microsoft.com/en-US/Download/confirmation.aspx?id=14632)
* [VCRedist 2013](https://www.microsoft.com/en-gb/download/details.aspx?id=40784)

## Building from source

The following commands will install dependencies, build libraries, and
run tests.

```
npm install
npm run build
npm test
```

> You can run the local `uno` directly using `node_modules/.bin/uno`. This
is useful when you want to build apps using your local Fuselibs development
environment.

### Express building

When working with the source code and building often, it can be beneficial
to build in *express mode*.

```
npm run build -- -e
```

> Express mode will only rebuild the package(s) that have actually changed,
skipping rebuilding all dependent packages.

### Manual testing

You can run the manual testing app on your desired platform using one of
the following commands:

```
npm run android
npm run dotnet
npm run ios
npm run native
```

## Contributing

> Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of
conduct, and the process for submitting pull requests to us.

### Reporting issues

Please report issues [here](https://github.com/fuse-open/fuselibs/issues).

## Contributors

### Code Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)]
<a href="https://github.com/fuse-open/fuselibs/graphs/contributors"><img src="https://opencollective.com/fuse-open/contributors.svg?width=890&button=false" /></a>

### Financial Contributors

 Become a financial contributor and help us sustain our community. [[Contribute](https://opencollective.com/fuse-open/contribute)]

#### Individuals

<a href="https://opencollective.com/fuse-open"><img src="https://opencollective.com/fuse-open/individuals.svg?width=890"></a>

#### Organizations

Support this project with your organization. Your logo will show up here with a link to your website. [[Contribute](https://opencollective.com/fuse-open/contribute)]

<a href="https://opencollective.com/fuse-open/organization/0/website"><img src="https://opencollective.com/fuse-open/organization/0/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/1/website"><img src="https://opencollective.com/fuse-open/organization/1/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/2/website"><img src="https://opencollective.com/fuse-open/organization/2/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/3/website"><img src="https://opencollective.com/fuse-open/organization/3/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/4/website"><img src="https://opencollective.com/fuse-open/organization/4/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/5/website"><img src="https://opencollective.com/fuse-open/organization/5/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/6/website"><img src="https://opencollective.com/fuse-open/organization/6/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/7/website"><img src="https://opencollective.com/fuse-open/organization/7/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/8/website"><img src="https://opencollective.com/fuse-open/organization/8/avatar.svg"></a>
<a href="https://opencollective.com/fuse-open/organization/9/website"><img src="https://opencollective.com/fuse-open/organization/9/avatar.svg"></a>
