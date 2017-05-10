"use strict";

var Mocha = require("mocha");
var mochaReporter = require("mocha-teamcity-reporter");

var moduleResolver = require("./moduleResolver");

var fs = require("fs");
var path = require("path");
global.XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest;

var testsDir = path.resolve(__dirname, "tests");

function runTests(opts, callback) {

    fs.readdir(testsDir, function(err, testFiles) {
        if (err) {
            callback(err);
            return;
        }

        var defaults = {};
        if (opts["teamcity"]){
            defaults.reporter = "mocha-teamcity-reporter";
        }

        var mocha = new Mocha(defaults);

        testFiles.forEach(function (testFileName) {
            if (path.extname(testFileName) === ".js") {
                var testFilePath = path.resolve(testsDir, testFileName);
                mocha.addFile(testFilePath);
            }
        });

        mocha.run(function (failures) {
            if (failures > 0) {
                var err = new Error("Test suite failed with " + failures + " failures.");
                err.failures = failures;
                callback(err);
            } else {
                callback(null);
            }
        });
    });
}

var opts = {};
process.argv.slice(2).join(" ").split("--").forEach(function (opt) {
    var optSplit = opt.split(" ");

    var key = optSplit[0];
    var value = optSplit[1] || true;

    if (key) {
        opts[key] = value;
    }
});


moduleResolver.create();

runTests(opts, function(err) {

    moduleResolver.clean();
    delete global.XMLHttpRequest;

    if (err) {
        process.exit(1);
    }
    process.exit(0);
});
