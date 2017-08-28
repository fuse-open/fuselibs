#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

typedef void (^DrawCallback)(void*);

@interface CanvasViewGroup : UIView

@property (copy) DrawCallback onDrawCallback;

-(instancetype)initWithDensity:(CGFloat)density;
-(void)setRenderBounds:(CGRect)bounds;

@end
