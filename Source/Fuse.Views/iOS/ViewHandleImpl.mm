#import "ViewHandleImpl.h"

@implementation ViewHandleImpl {
    id _unoObject;
    ViewHost* _view;
}

@synthesize view = _view;

-(instancetype)initWith:(id)unoObject withViewHost:(ViewHost*)view {
    if (self = [self init])
    {
        _unoObject = unoObject;
        _view = view;
    }
    return self;
}

-(void) setDataJson:(NSString*)json {
	[_view setDataJsonHandler](json);
}

-(void) setDataString:(NSString*)value forKey:(NSString*)key {
    [_view setDataStringHandler](value, key);
}

-(void) setCallback:(Callback)callback forKey:(NSString*)key {
	[_view setCallbackHandler](callback, key);
}

@end
