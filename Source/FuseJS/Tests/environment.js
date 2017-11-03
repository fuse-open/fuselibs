var Environment = require('FuseJS/Environment');

test.assert(iOS == Environment.ios, 'Environment.ios should be true on iOS');
test.assert(Android == Environment.android, 'Environment.android should be true on Android');
test.assert(!mobile == Environment.desktop, 'Environment.desktop should be true when not android or iOS');
test.assert(mobile == Environment.mobile, 'Environment.mobile should be false when not android or iOS');
test.assert(preview == Environment.preview, 'Environment.preview should be true in preview');

if (mobile) test.assert(Environment.mobileOSVersion != '', 'Environment.mobileOSVersion ("'+Environment.mobileOSVersion+'") should be non-empty string on mobile');
else test.assert(Environment.mobileOSVersion == '', 'Environment.mobileOSVersion ("'+Environment.mobileOSVersion+'") should be non-empty string on mobile');
