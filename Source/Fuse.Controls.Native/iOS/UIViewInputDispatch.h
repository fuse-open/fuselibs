#import <UIKit/UIKit.h>

typedef void(^InputHandler)(int,id,id);

void addInputHandler(UIView* view, InputHandler inputHandler, id visual);
void removeInputHandler(UIView* view);