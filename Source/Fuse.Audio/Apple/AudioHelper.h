#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@class SoundHandle;

@interface AudioHelper : NSObject
+ (AudioHelper*) getInstance;
- (NSNumber*)playSound:(NSData *)data;
- (NSNumber*)playSoundFromFile:(NSURL *)data;
- (void)kill:(SoundHandle *)handle;
@end

@interface SoundHandle : NSObject <AVAudioPlayerDelegate>
@property (nonatomic, retain) AVAudioPlayer *player;
-(id) initWithUrl:(NSURL*)url helper:(AudioHelper*)helper;
-(id) init:(NSData*)bytes helper:(AudioHelper*)helper;
-(void) play;
-(NSNumber*)getIdentifier;
@end
