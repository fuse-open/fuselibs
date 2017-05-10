var fw = require('/framework.js');
var fs = require("FuseJS/FileSystem");

fw.testStarted("FileSystem dataDirectory");
var dataDirectory = ("" + fs.dataDirectory);
fw.assertEqual(true, typeof dataDirectory === "string");
var dir = dataDirectory + "/";
console.log("fs.dataDirectory is " + dataDirectory)

fw.testStarted("FileSystem cacheDirectory");
var cacheDirectory = fs.cacheDirectory;
fw.assertEqual(true, typeof cacheDirectory === "string");
console.log("fs.cacheDirectory is " + cacheDirectory)

fw.testStarted("FileSystem listFiles listDirectories listEntries");
// Setup: Create a temporary directory with stuff
var testDir = dir + "FileSystem_list_test_" + Date.now();
var testDirContainedFile = testDir + "/file.txt"
var testDirContainedFileContent = "The file";
var testDirSubDir = testDir + "/subdir";
fs.createDirectorySync(testDir);
fs.writeTextToFileSync(testDirContainedFile, testDirContainedFileContent);
fs.createDirectorySync(testDirSubDir);
fs.listFilesSync(testDir);

fs.listFiles(testDir).then(function (files) {
    fw.assertEqual(1, files.length);
    fw.assertEqual(testDirContainedFile, files[0]);
}, function(error) {fw.testFailed("Unable to list files in directory" + error)}
).then(function () {
    return fs.listDirectories(testDir).then(function(directories) {
        fw.assertEqual(1, directories.length);
        fw.assertEqual(testDirSubDir, directories[0]);
    }, function (error) { fw.testFailed("Unable to list directories in directory" + error); })
}).then(function () {
    return fs.listEntries(testDir).then(function(entries) {
        fw.assertEqual(2, entries.length);
    }, function (error) { fw.testFailed("Unable to list entries in directory" + error); })
});

fw.testStarted("FileSystem writeTextToFile then readTextFromFile");
fs.writeTextToFile(dir + "writeTextToFile.tmp", "content").then(function() {
    fs.readTextFromFile(dir + "writeTextToFile.tmp").then(function(contents){
        fw.assertEqual("content", contents);
        // router.goto("passed");
    }, function(error){
        fw.testFailed("Could not read from file: " + error)
    });
}).catch(function(error){
    fw.testFailed("Writing threw an error: " + error);
});

fw.testStarted("FileSystem exists");
fs.writeTextToFileSync(dir + "fileThatExists.tmp", "content")
fs.exists(dir + "fileThatExists.tmp").then(function(fileExists){
    fw.assertEqual(true, fileExists);
    // router.goto("passed");
}, function(error){
    fw.testFailed("Could not check if file exists due to error: " + error)
});

fw.testStarted("FileSystem writeBufferToFile then readBufferFromFile");
var writtenBuffer = new ArrayBuffer(4);
var bufferView = new Uint32Array(writtenBuffer);
bufferView[0] = 0xdeadb001;
fs.writeBufferToFile(dir + "writeBufferToFile.tmp", writtenBuffer).then(function() {
    fs.readBufferFromFile(dir + "writeBufferToFile.tmp").then(function(readBuffer){
        fw.assertEqual(4, readBuffer.byteLength);
        fw.assertEqual(0xdeadb001, (new Uint32Array(readBuffer))[0]);
        router.goto("passed");
    }, function(error){
        fw.testFailed("Could not read from file: " + error)
    });
}).catch(function(error){
    fw.testFailed("Writing threw an error: " + error);
});


// Helper function to check that object is a recent Date (+-)1 minute
function assertDateIsValid(dt)
{
    fw.assertEqual(true, dt instanceof Date);
    var now = new Date();
    var msDiff = Math.abs(now.getTime() - dt.getTime());
    if (msDiff > 60 * 1000 /* 1min */)
        fw.testFailed("Expected a date +-1 minute of now (" + now + "), but was " + dt);
}

fw.testStarted("FileSystem getDirectoryInfo");
fs.getDirectoryInfo(testDir, writtenBuffer).then(function(info) {
    fw.assertEqual(true, info.exists);
    fw.assertEqual(info.fullName, testDir);
    // Just check that the timestamps is correct within a 10 minute bound
    assertDateIsValid(info.lastWriteTime);
    assertDateIsValid(info.lastAccessTime);
}).catch(function(error){
    fw.testFailed("getFileInfo threw error: " + error);
});


fw.testStarted("FileSystem getFileInfo");
fs.getFileInfo(testDirContainedFile, writtenBuffer).then(function(info) {
    fw.assertEqual(testDirContainedFileContent.length, info.length);
    fw.assertEqual(true, info.exists);
    fw.assertEqual(info.fullName, testDirContainedFile);
    // Just check that the timestamps is correct within a 10 minute bound
    assertDateIsValid(info.lastWriteTime);
    assertDateIsValid(info.lastAccessTime);
}).catch(function(error){
    fw.testFailed("getFileInfo threw error: " + error);
});


fw.testStarted("FileSystem move");
var moveSource = dir + "moved-source" + Date.now() + ".txt";
var moveDest = dir + "moved-dest" + Date.now() + ".txt";
fs.writeTextToFile(moveSource, "hello")
    .then(function() { return fs.move(moveSource, moveDest) })
    .then(function() { return fs.exists(moveDest) })
    .then(function(existsResult) { fw.assertEqual(true, existsResult) })
    .catch(function(error) { fw.testFailed("FileSystem move threw error: " + error) });


fw.testStarted("FileSystem moveSync");
var moveSyncSource = dir + "moved-sync-source" + Date.now() + ".txt";
var moveSyncDest = dir + "moved-sync-dest" + Date.now() + ".txt";
fs.writeTextToFile(moveSyncSource, "hello")
    .then(function() { 
        fs.moveSync(moveSyncSource, moveSyncDest);
        return fs.exists(moveSyncDest);
    })
    .then(function(existsResult) { fw.assertEqual(true, existsResult) })
    .catch(function(error) { fw.testFailed("FileSystem moveSync threw error: " + error) });


fw.testStarted("FileSystem readTextFromFile that does not exist throws exception");
fs.readTextFromFile("this-file-certainly-do-not-exist" + Date.now() + ".txt")
    .then(function() { fw.testFailed("Should have thrown exception"); })
    .catch(function(error) {
        fw.assertEqual(true, error.includes("this-file-certainly-do-not-exist"));
    });



fw.testStarted("FileSystem copy");
var startTime = Date.now();
var copySource = dir + "copy-source/" + startTime + "/";
var firstCopySource = copySource + "1.txt";
var secondCopySource = copySource + "2.txt";
var copyDest = dir + "copy-dest/" + startTime + "/";
var firstCopyDest = copyDest + "1.txt";
var secondCopyDest = copyDest + "2.txt";

fs.createDirectorySync(copySource);
fs.writeTextToFile(firstCopySource, "hello\n")
    .then(function() { return fs.writeTextToFile(secondCopySource, "you too\n") })
    .then(function() { return fs.copy(copySource, copyDest) })
    .then(function() { return fs.exists(firstCopyDest) })
    .then(function(existsResult) { fw.assertEqual(true, existsResult) })
    .catch(function(error) { fw.testFailed("FileSystem move threw error: " + error) });


fw.testStarted("FileSystem copySync");
var startTime = Date.now();
var copySyncSource = dir + "copy-sync-source/" + startTime + "/";
var firstCopySyncSource = copySyncSource + "1.txt";
var secondCopySyncSource = copySyncSource + "2.txt";
var copySyncDest = dir + "copy-sync-dest/" + startTime + "/";
var firstCopySyncDest = copySyncDest + "1.txt";
var secondCopySyncDest = copySyncDest + "2.txt";

fs.createDirectorySync(copySyncSource);
fs.writeTextToFile(firstCopySyncSource, "hello\n")
    .then(function() { return fs.writeTextToFile(secondCopySyncSource, "you too\n") })
    .then(function() {  
        fs.copySync(copySyncSource, copySyncDest);
        return fs.exists(firstCopySyncDest);
    })
    .then(function(existsResult) { fw.assertEqual(true, existsResult) })
    .catch(function(error) { fw.testFailed("FileSystem move threw error: " + error) });



// Android specific tests
var env = require('FuseJS/Environment');

if (env.android)
{
    fw.testStarted("FileSystem.androidPaths check that all properties returns a string");
    fw.assertEqual(true, typeof fs.androidPaths.files === "string");
    fw.assertEqual(true, typeof fs.androidPaths.cache === "string");
    fw.assertEqual(true, typeof fs.androidPaths.externalFiles === "string");
    fw.assertEqual(true, typeof fs.androidPaths.externalCache === "string");
}

if (env.ios)
{
    fw.testStarted("FileSystem.iosPaths check that all properties returns a string");


    console.log(JSON.stringify(fs.iosPaths, null, "  "));

    fw.assertEqual(true, typeof fs.iosPaths.caches === "string");
    fw.assertEqual(true, typeof fs.iosPaths.library === "string");
    fw.assertEqual(true, typeof fs.iosPaths.documents === "string");
}

