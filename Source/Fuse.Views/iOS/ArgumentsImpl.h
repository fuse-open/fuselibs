#include "Arguments.h"

@interface ArgumentsImpl : Arguments

@property (copy) id (^getArgsHandler)();
@property (copy) id (^getDataJsonHandler)();

@end