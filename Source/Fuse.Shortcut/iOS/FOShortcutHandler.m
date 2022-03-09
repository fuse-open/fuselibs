#import "FOShortcutHandler.h"

@interface FOShortcutHandler ()
@property(nonatomic, retain) NSString *shortcutType;
@property(nonatomic, assign) BOOL _pendingCall;
@end

@implementation FOShortcutHandler

static FOShortcutHandler * instance = nil;

@synthesize _onCallback;

+(instancetype)sharedInstance
{
    if (instance == nil)
        instance = [[FOShortcutHandler alloc] init];
    return instance;
}

-(void)registerCallback:(void (^)(NSString* shortcutType))_onCallback
{
    self._onCallback = _onCallback;
    if (self._pendingCall)
        [self handleShortcut:self.shortcutType];
}

-(void)registerShortcuts:(NSArray*)shortcuts
{

     NSMutableArray<UIApplicationShortcutItem *> *newShortcuts = [[NSMutableArray alloc] init];

    for (NSDictionary* item in shortcuts)
    {
        UIApplicationShortcutIcon *icon = nil;
        if (item[@"icon"] != nil)
            icon = [UIApplicationShortcutIcon iconWithTemplateImageName:item[@"icon"]];
        UIApplicationShortcutItem *shortcut = [[UIApplicationShortcutItem alloc] initWithType:item[@"id"] localizedTitle:item[@"title"] localizedSubtitle:item[@"subtitle"] icon:icon userInfo:nil];
        [newShortcuts addObject:shortcut];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].shortcutItems = @[];
        [UIApplication sharedApplication].shortcutItems = newShortcuts;
    });
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIApplicationShortcutItem *shortcutItem = launchOptions[UIApplicationLaunchOptionsShortcutItemKey];
    if (shortcutItem)
    {
        self.shortcutType = shortcutItem.type;
        return NO;
    }
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.shortcutType) {
        [self handleShortcut:self.shortcutType];
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler
{
    [self handleShortcut:shortcutItem.type];
}

-(void)handleShortcut:(NSString*)type
{
    if (self._onCallback != nil)
    {
        self._onCallback(type);
        self._pendingCall = NO;
        self.shortcutType = nil;
    }
    else
        self._pendingCall = YES;
}
@end