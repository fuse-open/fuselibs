#import "NoZoomDelegate.h"
@implementation NoZoomDelegate
  -(UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView 
  {
    return nil;
  }
@end
