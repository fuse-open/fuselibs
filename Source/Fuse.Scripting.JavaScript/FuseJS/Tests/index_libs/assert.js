var assert = (function() {
    function assert_equals(value, expectedValue) {
        var message = "";

        if(value != expectedValue) {
            message = "Expected " + expectedValue + ", but got " + value;
            throw Error(message);
        }
    }

    return {
        equal: assert_equals
    }
})();