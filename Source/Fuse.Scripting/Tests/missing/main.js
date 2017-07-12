try {
    require('bogus');
    test.assert(false, 'FAIL require throws error when module missing');
} catch (exception) {
    test.assert(true, 'PASS require throws error when module missing');
}
