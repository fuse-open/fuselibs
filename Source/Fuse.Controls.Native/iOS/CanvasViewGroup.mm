#import "CanvasViewGroup.h"

@interface CanvasLayer : CALayer

@property (copy) DrawCallback onDrawCallback;

@property CGFloat translateX;
@property CGFloat translateY;

@end

@implementation CanvasLayer

-(void)drawInContext:(CGContextRef)ctx {
	[self removeAllAnimations];
	[super drawInContext:ctx];
	if (self.onDrawCallback != NULL)
	{
		CGContextTranslateCTM(ctx, self.translateX, self.translateY);

		CGAffineTransform t = CGContextGetCTM(ctx);

		CGFloat scaleX = sqrt((t.a * t.a) + (t.b + t.b));
		CGFloat scaleY = sqrt((t.c * t.c) + (t.d * t.d));

		CGAffineTransform scale = CGAffineTransformInvert(CGAffineTransformMakeScale(scaleX, scaleY));
		CGContextConcatCTM(ctx, scale);

		self.onDrawCallback(ctx);
	}
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
	_canvasLayer.frame = bounds;
	_canvasLayer.translateX = -bounds.origin.x;
	_canvasLayer.translateY = -bounds.origin.y;
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