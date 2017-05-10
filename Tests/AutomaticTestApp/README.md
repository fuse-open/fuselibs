# Automatic test app

The automatic test app is intended for systems level testing.

## Running the test app
In the `/Tests` directory:

`./auto-test-app.sh <target>`, for instance `./auto-test-app.sh cmake`

## Adding tests
The easiest is probably to look at an existing part, for instance the one in `Demonstration.ux`, which is a minimal demonstration of how to write tests. Here are the steps needed to make a part of your own:
- In the `/Tests/AutomaticTestApp/Parts` directory, add a `<Page>`, taking a `<Router>` as a dependency.
- Add the name of the test in a `<Text>` in the page, to make it easier for humans to see the progress
- Add this page to the end of the list in `MainView.ux`.
- In your test code, require the test framework `var fw = require('/framework.js')`
- Write test code. If the test fails, call `fw.testFailed("<reason>")`, if it succeeds, call `router.goto("passed")`
- Insert your test into the sequence, by modifying the last test in the list from `router.goto("passed")` to `router.goto("<your test name>")`
- Run the tests, and see that your test gets called and passes

## Helper methods
- `fw.assertEqual(<expected>, <actual>)` will compare the values, and if they are `!==`, print an error message and fail the test

## How it works 
`auto-test-app.sh` will start the app, and listen for a message that signals its completion. If that message doesn't arrive, the test is considered to have failed. The test also fails if the test app hangs.

This is first intended to run with `uno build -r` in the fuselibs repo, but will also be used in the Fuse repo with `fuse preview`.
