#import <Foundation/Foundation.h>

@interface FOShortcutHandler : NSObject

+(instancetype)sharedInstance;

@property (nonatomic, copy) void (^_onCallback)(NSString* shortcutType);


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler;

-(void)registerShortcuts:(NSArray*)shortcuts;
-(void)registerCallback:(void (^)(NSString* shortcutType))_onCallback;
-(void)handleShortcut:(NSString*)type;
@end
