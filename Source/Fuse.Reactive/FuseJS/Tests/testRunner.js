
/*
	This folder structure + testRunner.js are here as a temp hack for TeamCity (hard coded for the old folder structure) to be able to run
	the tests that have moved to Fuse.Reactive.JavaScript
*/
var fork = require('child_process').fork;
var child = fork('Source/Fuse.Scripting.JavaScript/FuseJS/tests/testRunner', process.argv.splice(2));
child.on('exit', function(code) { process.exit(code); });
