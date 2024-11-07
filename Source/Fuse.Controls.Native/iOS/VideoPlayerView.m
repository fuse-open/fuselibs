
#import "VideoPlayerView.h"

@implementation VideoPlayerView

	@synthesize player;
	@synthesize playerLayer;
	@synthesize onLoadingCallback;
	@synthesize onReadyCallback;
	@synthesize onCompleteCallback;
	@synthesize onErrorCallback;
	@synthesize onFrameAvailableCallback;


	+ (Class)layerClass {
		return [AVPlayerLayer class];
	}

	- (instancetype)initWithFrame:(CGRect)frame {
		self = [super initWithFrame:frame];
		if (self) {
			self.player = [[AVPlayer alloc] init];
			self.playerLayer = (AVPlayerLayer *)self.layer;
			self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
			self.playerLayer.player = self.player;
		}
		return self;
	}

	- (void)layoutSubviews {
		[super layoutSubviews];
		self.playerLayer.frame = self.bounds;
	}

	- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
	{
		AVPlayer * player = (AVPlayer *)object;
		CGSize size = [[player currentItem] presentationSize];
		CGFloat screenScale = [[UIScreen mainScreen] scale];

		if ([keyPath isEqualToString:@"currentItem.status"]) {
			if ([player currentItem].status == AVPlayerItemStatusReadyToPlay) {
				if (onReadyCallback != NULL)
					onReadyCallback();
			}
			else if ([player currentItem].status == AVPlayerItemStatusFailed) {
				if (onErrorCallback != NULL)
					onErrorCallback([player currentItem].error.localizedDescription);
			}
		} else if ([keyPath isEqualToString:@"currentItem.playbackLikelyToKeepUp"]) {
			if ([player currentItem].playbackLikelyToKeepUp) {
				if (onFrameAvailableCallback != NULL)
					onFrameAvailableCallback();
			}else {
				if ([player currentItem].playbackBufferEmpty)
					if (onLoadingCallback != NULL)
						onLoadingCallback();
			}
		} else if ([keyPath isEqualToString:@"currentItem.playbackBufferFull"]) {
			if ([player currentItem].playbackBufferFull) {
				if (onFrameAvailableCallback != NULL)
					onFrameAvailableCallback();
			}
		} else if ([keyPath isEqualToString:@"currentItem.playbackBufferEmpty"]) {
			if ([player currentItem].playbackBufferEmpty) {
				if (onLoadingCallback != NULL)
					onLoadingCallback();
			} else {
				if ([player currentItem].playbackLikelyToKeepUp) {
					if (onFrameAvailableCallback != NULL)
						onFrameAvailableCallback();
				}
			}
		} else {
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
	}

	- (void)contentDidFinishPlaying:(NSNotification *)notification
	{
		if (onCompleteCallback != NULL)
			onCompleteCallback();
	}
@end
