


## Getting started

JavaScript can be used in UX markup through the `JavaScript` class, either by pointing to external JavaScript files, like this:

	<JavaScript File="SomeCode.js" />

Or by inlining the JavaScript code in the tag, like this:

	<JavaScript>
		console.log("Hello, FuseJS!");
	</JavaScript>

## About FuseJS 

FuseJS is a JavaScript framework for writing cross-platform mobile app business logic. It consists of a bunch of classes that covers
the basic functionality required for creating native mobile apps, as well as the @Observable class which lets you expose data to the UI in a functional reactive way.

## Modules

FuseJS implements the <a href="http://www.commonjs.org/">CommonJS</a> module system. Each code file or inline snippet is a _module_.

In order to expose data and functions to other modules, one can add them to the `module.exports` object:

	<JavaScript>
		module.exports = {
			exportedSymbol: "Hello, rest of the world!"
		};
	</JavaScript>

Failing to export from modules will make it impossible to reach defined data inside the module:

	<JavaScript>
		var data = [1, 2, 3];
		var invisible = "I'm invisible";

		module.exports = {
			data: data
		};
	</JavaScript>

This is good for hiding implementation details from other calling JavaScript modules and UX code.


## Importing modules

Each code file (or inline snippet) defines a module.

You can import JavaScript modules by their file name. To do this, make sure your JavaScript files are included in your .unoproj file as "Bundle" files:


	"Includes": [
		"yourJavaScriptFile.js:Bundle"
		..other files ..
	]

or if you want to make all JavaScript files be includes as bundled files:

	"Includes": [
		"**.js:Bundle"
	]

Then, you can require using the JavaScript file name:

	var myModule = require('/someJavaScriptFile.js');


Note that prefixing the file name with a "/" means that we are looking for the file relative to the project root directory. To name a file relative to the current file, prefix with "./". By omitting the prefixes, the file name is relative to the project root, or the global module it's in.

	var relativeToProjectRoot = require('/SomeComponent');
	var relativeFile = require('./MainView');
	var relativeToRootOrGlobalModule = require('SomeOtherComponent.js');

> Note that you may omit the .js file extension in the file name if you wish

## Module instancing

Fuse's treatment of the `<JavaScript>` tag has some important differences from how modules work in the <a href="http://www.commonjs.org/">CommonJS</a> module system.

A module inside a `<JavaScript>` tag (or pointed to in an external file) will be instantiated once *for each time* the surrounding UX scope is instantiated. This means that if the `<JavaScript>` tag is part of a component, each instance of that component will initialise the code and have a separate set of the local variables and exports.

### Cleaning up after modules

In Fuse, a JavaScript module can correspond to multiple module instances that get created and destroyed on the fly. If your module allocates resources that need manual cleanup, such as creating explicit `Observable` subscriptions, you can assign a handler to `module.disposed` and clean up after yourself there.

Example:

	var foo = getSomeGlobalObservable();

	function fooChanged() { ... }
	
	foo.addSubscriber(fooChanged);

	...

	module.disposed = function () {
		foo.removeSubscriber(fooChanged)
	}

## Design and motivation

The key design goal of FuseJS is to keep your JavaScript code small, clean and only concerned with the practical functions of your application. Meanwhile
all things related to UX, such as layout, data presentation, animation and gesture response, is left to declarative UX markup and native UI components.

The way Fuse separates JavaScript business logic from UX markup presentation has some clear benefits:

* Performance - all the performance critical bits are handled in native code and based on native UI components.
* Easy - declarative code is easy to read, write and understand even with limited programming knowledge
* Less error prone - fewer states means fewer things can go wrong
  * Visual tooling - UX markup can be edited by Fuse tools such as inspectors, timelines and generally cool drag & droppy stuff.

Note that Fuse has tons of declarative APIs (designed for UX markup) that replace the need for controlling animation from JavaScript (i.e. imperatively).

Many other JavaScript frameworks mix imperative UI code, animation and performance critical tasks into JavaScript, hence many people new to FuseJS tend to try
doing things this way in the beginning. While most of these things are technically possible in FuseJS, it is discouraged. We recommend taking some
time to study the Fuse examples to get a feel for the new way of doing things.

Purifying your code by separating view and logic into UX markup and JavaScript can shrink your code base significantly, make it more maintainable, and allow
more effective collaboration between UX designers and developers.

If you need to write performance-critical business logic, we recommend doing that in native code or alternatively in Uno code instead of in JavaScript.
