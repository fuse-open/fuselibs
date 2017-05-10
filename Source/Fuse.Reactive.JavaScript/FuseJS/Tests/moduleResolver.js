"use strict";

var fs = require("fs");
var path = require("path");

var fuseJsModules = JSON.parse(fs.readFileSync(path.resolve(__dirname, "fusejs-modules.json"), "utf8"));

var targetPath = path.resolve(__dirname, "../");

function createNodeModules() {

    ensureFolder("node_modules");

    fuseJsModules.forEach(function(item) {
        var root = "node_modules";
        var requirePath = "../";
        var moduleName;
        item.split("/").forEach(function(folder) {
            root = root + "/" + folder;
            ensureFolder(root);

            requirePath += "../";
            moduleName = folder;
        });

        requirePath = requirePath + moduleName;
        fs.writeFileSync(path.join(targetPath, root + "/index.js"),
            "module.exports = require('" + requirePath + "');");
    });
}

function ensureFolder(folderName) {
    var folderPath = path.resolve(targetPath, folderName);
    if (!fs.existsSync(folderPath)) {
        fs.mkdirSync(folderPath);
    }
}

function cleanNodeModules() {
     rmdir(path.resolve(targetPath, "node_modules"));
}

var rmdir = function(dir) {
     var list = fs.readdirSync(dir);
    for(var i = 0; i < list.length; i++) {
        var filename = path.join(dir, list[i]);
        var stat = fs.statSync(filename);

        if(filename == "." || filename == "..") {
            // pass these files
        } else if(stat.isDirectory()) {
            // rmdir recursively
            rmdir(filename);
        } else {
            // rm filename
            fs.unlinkSync(filename);
        }
    }
    fs.rmdirSync(dir);
};

module.exports = {
    create: createNodeModules,
    clean: cleanNodeModules
};
