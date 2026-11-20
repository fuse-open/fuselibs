#!/usr/bin/env node
//
// Rename the v8::platform::NewDefaultPlatform symbol in the prebuilt V8 static libraries, so they
// link against a newer Android NDK than the one they were built with.
//
// The libraries were built against NDK 21's libc++, where Uno's _LIBCPP_ABI_NAMESPACE=__Cr was
// honoured. Newer NDKs ignore that macro and use __ndk1 instead, so the one V8 API whose mangled
// name takes a std type no longer matches and linking fails with an undefined symbol taking
// std::__ndk1::unique_ptr<v8::TracingController>. The machine-level ABI is unchanged, so renaming
// the symbol inside libv8.a is enough.
//
// Usage: node patch-v8-abi.js [lib-dir]    (default: android/lib next to this script)
//
// Both V8/android/lib and Source/build/Fuse.Scripting.JavaScript/V8/android/lib are recreated when
// the NuGet package is extracted, so this has to run afterwards -- prepack does that. Rerun it by
// hand after a fresh clone or a cleaned build directory.
//
// llvm-objcopy is taken from $OBJCOPY, PATH, or a local NDK. When it or the libraries are missing
// the script warns and exits 0, so it never fails a prepack. Runs on macOS, Linux and Windows.

const { execFileSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const OLD =
	"_ZN2v88platform18NewDefaultPlatformEiNS0_15IdleTaskSupportENS0_21InProcessStackDumpingENSt4__Cr10unique_ptrINS_17TracingControllerENS3_14default_deleteIS5_EEEE";
const NEW =
	"_ZN2v88platform18NewDefaultPlatformEiNS0_15IdleTaskSupportENS0_21InProcessStackDumpingENSt6__ndk110unique_ptrINS_17TracingControllerENS3_14default_deleteIS5_EEEE";

const isWindows = process.platform === "win32";
const objcopyName = isWindows ? "llvm-objcopy.exe" : "llvm-objcopy";
const dir = process.argv[2] || path.join(__dirname, "android", "lib");

function subdirs(root) {
	try {
		return fs
			.readdirSync(root)
			.sort()
			.reverse()
			.map((x) => path.join(root, x));
	} catch (e) {
		return [];
	}
}

function isExecutable(file) {
	try {
		fs.accessSync(file, fs.constants.X_OK);
		return true;
	} catch (e) {
		return false;
	}
}

function findInPath() {
	for (const entry of (process.env.PATH || "").split(path.delimiter)) {
		if (!entry) continue;

		const candidate = path.join(entry, objcopyName);

		if (isExecutable(candidate)) return candidate;
	}

	return null;
}

function readConfigSdk() {
	try {
		const config = fs.readFileSync(
			path.join(os.homedir(), ".unoconfig"),
			"utf8",
		);
		const match = /^\s*android\.sdk\s*:\s*(.+)$/m.exec(config);

		return match ? match[1].trim().replace(/^[`"']|[`"']$/g, "") : null;
	} catch (e) {
		return null;
	}
}

function sdkRoots() {
	const roots = [
		process.env.ANDROID_NDK,
		process.env.ANDROID_HOME,
		process.env.ANDROID_SDK_ROOT,
		readConfigSdk(),
	];

	if (isWindows)
		roots.push(path.join(process.env.LOCALAPPDATA || "", "Android", "Sdk"));
	else if (process.platform === "darwin")
		roots.push(path.join(os.homedir(), "Library", "Android", "sdk"));
	else roots.push(path.join(os.homedir(), "Android", "Sdk"));

	return roots
		.filter((x) => !!x)
		.map((x) => x.replace(/^~(?=$|[\\/])/, os.homedir()));
}

function findObjcopy() {
	if (process.env.OBJCOPY && isExecutable(process.env.OBJCOPY))
		return process.env.OBJCOPY;

	const inPath = findInPath();

	if (inPath) return inPath;

	// Each entry is either an SDK root (containing ndk/<version>) or an NDK itself.
	for (const root of sdkRoots()) {
		for (const ndk of [root].concat(subdirs(path.join(root, "ndk")))) {
			for (const host of subdirs(
				path.join(ndk, "toolchains", "llvm", "prebuilt"),
			)) {
				const candidate = path.join(host, "bin", objcopyName);

				if (isExecutable(candidate)) return candidate;
			}
		}
	}

	return null;
}

const objcopy = findObjcopy();

if (!objcopy) {
	console.error(
		"patch-v8-abi: skipped -- llvm-objcopy not found (set OBJCOPY or ANDROID_NDK to patch V8 for a newer NDK)",
	);
	process.exit(0);
}

let found = 0;

for (const abi of subdirs(dir)) {
	const lib = path.join(abi, "libv8.a");

	if (!fs.existsSync(lib)) continue;

	found++;

	try {
		execFileSync(objcopy, ["--redefine-sym", `${OLD}=${NEW}`, lib], {
			stdio: "inherit",
		});
	} catch (e) {
		console.error(`patch-v8-abi: failed to patch ${lib}`);
		process.exit(1);
	}
}

if (!found) {
	console.error(
		`patch-v8-abi: skipped -- no libv8.a under '${dir}' (nothing extracted yet)`,
	);
	process.exit(0);
}

console.log(`patch-v8-abi: patched libv8.a under ${dir}`);
