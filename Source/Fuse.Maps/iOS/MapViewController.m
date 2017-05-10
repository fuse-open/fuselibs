#import "MapViewController.h"
@implementation MapViewController
{
  id _view;
}

-(id)initWithView:(id)view onAppeared:(Action)appearedHandler onResize:(Action)resizeHandler
{
  self = [super init];
  _view = view;
  self.onAppearedCallback = appearedHandler;
  self.onResizeCallback = resizeHandler;
  return self;
}

-(void)loadView
{
  self.view = _view;
}

-(void)viewDidLayoutSubviews
{
  if(self.onResizeCallback!=nil && self.view.frame.size.width > 0)
    self.onResizeCallback();
}

-(void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if(self.onAppearedCallback!=nil)
    self.onAppearedCallback();
}
@end
