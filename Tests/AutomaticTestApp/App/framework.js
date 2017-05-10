function suiteStarted()
{
    console.log("Starting tests");
}
function testStarted(test_name)
{
    console.log("Starting test:" + test_name);
}

function testFailed(error_msg)
{
    console.log(error_msg);
    console.log("TEST_APP_MSG:ERROR");
}

function suitePassed()
{
    console.log("TEST_APP_MSG:OK")
}

function assertEqual(v1, v2)
{
    if(v1 !== v2)
    {
        testFailed("Expected '" + v1 + "', but got '" + v2 + "'");
    }
}

module.exports =
{
    testStarted: testStarted,
    testFailed: testFailed,
    suiteStarted: suiteStarted,
    suitePassed: suitePassed,
    assertEqual: assertEqual
}
