#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

typedef void (^LoadingCallback)(void);
typedef void (^ReadyCallback)(void);
typedef void (^CompleteCallback)(void);
typedef void (^OnFrameAvailableCallback)(void);
typedef void (^ErrorCallback)(NSString*);

@interface VideoPlayerView : UIView

	@property (nonatomic, strong) AVPlayer *player;
	@property (nonatomic, strong) AVPlayerLayer *playerLayer;
	@property (nonatomic, strong) LoadingCallback onLoadingCallback;
	@property (nonatomic, strong) ReadyCallback onReadyCallback;
	@property (nonatomic, strong) CompleteCallback onCompleteCallback;
	@property (nonatomic, strong) OnFrameAvailableCallback onFrameAvailableCallback;
	@property (nonatomic, strong) ErrorCallback onErrorCallback;

	- (void)contentDidFinishPlaying:(NSNotification *)notification;

@end
