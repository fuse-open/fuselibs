#import <UIKit/UIKit.h>

const int EVENTTYPE_PRESSED = 0;
const int EVENTTYPE_MOVED = 1;
const int EVENTTYPE_RELEASED = 2;
const int EVENTTYPE_CANCELLED = 3;

typedef void(^InputHandler)(int,id,id);

void addInputHandler(UIView* view, InputHandler inputHandler, id visual);
void removeInputHandler(UIView* view);