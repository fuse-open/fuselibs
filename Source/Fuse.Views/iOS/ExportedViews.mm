#import "ExportedViews.h"

static ExportedViews* _instance;

@implementation ExportedViews {
    ViewHandle* (^_templateFactory)(NSString*);
}

+(ViewHandle*)instantiate:(NSString*)templateName {
    if (_instance)
    {
        return _instance->_templateFactory(templateName);
    }
    NSException* notInitialized = [NSException
                                   exceptionWithName:@"Failed to instantiate template"
                                   reason:@"ExportedViews not initialized"
                                   userInfo: nil];
    @throw notInitialized;
}

+(void)initialize:(ViewHandle* (^)(NSString*))templateFactory {
    _instance = [[ExportedViews alloc] init];
    _instance->_templateFactory = templateFactory;
}

@end