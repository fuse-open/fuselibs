#import "ViewHost.h"

@implementation ViewHost

-(CGSize)sizeThatFits:(CGSize)size
{
    if (_sizeThatFitsHandler)
        return _sizeThatFitsHandler(size);
    else
        return [super sizeThatFits:size];
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (_setFrameHandler)
        _setFrameHandler(frame);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_inputEventHandler)
        _inputEventHandler(self, event);
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_inputEventHandler)
        _inputEventHandler(self, event);
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_inputEventHandler)
        _inputEventHandler(self, event);
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_inputEventHandler)
        _inputEventHandler(self, event);
    [super touchesCancelled:touches withEvent:event];
}

@end
