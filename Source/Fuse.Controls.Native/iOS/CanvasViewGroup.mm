#import "CanvasViewGroup.h"

@interface CanvasLayer : CALayer

@property (copy) DrawCallback onDrawCallback;

@end

@implementation CanvasLayer

-(void)drawInContext:(CGContextRef)ctx {
	[self removeAllAnimations];
    [super drawInContext:ctx];
    if (self.onDrawCallback != NULL)
    	self.onDrawCallback(ctx);
}

@end

@implementation CanvasViewGroup {
	CanvasLayer* _canvasLayer;
}

-(instancetype)initWithDensity:(CGFloat)density {
	if (self = [super init])
	{
		_canvasLayer = [[CanvasLayer alloc] init];
		_canvasLayer.shouldRasterize = false;
		_canvasLayer.contentsScale = density;
		_canvasLayer.drawsAsynchronously = true;
		_canvasLayer.actions = @{
			@"onOrderIn": [NSNull null],
			@"onOrderOut": [NSNull null],
			@"sublayers": [NSNull null],
			@"contents": [NSNull null],
			@"bounds": [NSNull null]
		};
		[self.layer addSublayer:_canvasLayer];
	}
	return self;
}

-(void)setRenderBounds:(CGRect)bounds {
}

-(void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	self.layer.frame = self.bounds;
    _canvasLayer.frame = self.bounds;
	[_canvasLayer setNeedsDisplay];
}

-(void)setNeedsDisplay {
	[_canvasLayer setNeedsDisplay];
	[super setNeedsDisplay];
}

-(void)setOnDrawCallback:(DrawCallback)callback {
	_canvasLayer.onDrawCallback = callback;
}

-(DrawCallback)onDrawCallback {
	return _canvasLayer.onDrawCallback;
}

@end