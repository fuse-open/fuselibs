#include "ArgumentsImpl.h"

@implementation ArgumentsImpl

-(NSDictionary<NSString*,NSString*>*)args
{
	return self.getArgsHandler();
}

-(NSString*)dataJson
{
	return self.getDataJsonHandler();
}

@end