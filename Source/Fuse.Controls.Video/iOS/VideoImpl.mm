#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <AVFoundation/AVFoundation.h>
#import <iOS/VideoImpl.h>
#import <OpenGLES/ES2/glext.h>

#include <cstdlib>

@interface PresentationSizeObserver : NSObject
@end

namespace FuseVideoImpl
{

	struct VideoState
	{
		AVPlayer * Player;
		AVPlayerItem * PlayerItem;
		AVPlayerItemVideoOutput * PlayerItemVideoOutput;
		AVURLAsset * Asset;
		CVOpenGLESTextureRef TextureHandle;
		CVOpenGLESTextureCacheRef TextureCacheHandle;
		uDelegate * ErrorHandler;
		uDelegate * LoadedHandler;
		int Width, Height;
		PresentationSizeObserver * _presentationSizeObserver;
	};
}

@implementation PresentationSizeObserver
	- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
	{
		FuseVideoImpl::VideoState *vs = (FuseVideoImpl::VideoState *)context;
		auto size = [[vs->Player currentItem] presentationSize];
		auto screenScale = [[UIScreen mainScreen] scale];

		vs->Width = (int)floor(size.width * screenScale + 0.5f);
		vs->Height = (int)floor(size.height * screenScale + 0.5f);

		if(vs->LoadedHandler != NULL)
		{
			@{Uno.Action:Of(vs->LoadedHandler):Call()};
			uRelease(vs->LoadedHandler);
			vs->LoadedHandler = NULL;
		}
	}
@end

namespace FuseVideoImpl
{
	void setErrorHandler(void * videoState, uDelegate * errorHandler)
	{
		VideoState * vs = (VideoState*)videoState;

		if (vs->ErrorHandler)
		{
			uRelease(vs->ErrorHandler);
			vs->ErrorHandler = NULL;
		}

		if (errorHandler)
		{
			uRetain(errorHandler);
			vs->ErrorHandler = errorHandler;
		}

	}

	void cleanup(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		if (vs->TextureHandle)
		{
			CFRelease(vs->TextureHandle);
			vs->TextureHandle = NULL;
		}
		// Periodic texture cache flush every frame
		CVOpenGLESTextureCacheFlush(vs->TextureCacheHandle, 0);
	}

	void * allocateVideoState()
	{
		void * videoState = malloc(sizeof(struct VideoState));
		memset(videoState, 0, sizeof(struct VideoState));
		return videoState;
	}

	void freeVideoState(void * videoState)
	{
		cleanup(videoState);

		VideoState * vs = (VideoState*)videoState;

		if (vs->TextureCacheHandle)
			CFRelease(vs->TextureCacheHandle);

		if (vs->Player)
		{
			if (vs->_presentationSizeObserver)
			{
				[vs->Player removeObserver:vs->_presentationSizeObserver forKeyPath:@"currentItem.presentationSize"];
				vs->_presentationSizeObserver = NULL;
			}
			[vs->Player pause];
			vs->Player = NULL;
		}

		vs->PlayerItem = NULL;
		vs->PlayerItemVideoOutput = NULL;
		vs->Asset = NULL;

		if (vs->ErrorHandler)
		{
			uRelease(vs->ErrorHandler);
			vs->ErrorHandler = NULL;
		}

		free(videoState);
	}

	void initialize(void * videoState, NSString * uri, uDelegate * loadedCallback, uDelegate * errorCallback)
	{
		VideoState * vs = (VideoState*)videoState;

		if (loadedCallback != NULL)
			uRetain(loadedCallback);

		if (errorCallback != NULL)
			uRetain(errorCallback);

		#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
		CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, &(vs->TextureCacheHandle));
		#else
		CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[EAGLContext currentContext], NULL, &(vs->TextureCacheHandle));
		#endif

		NSURL * url = [NSURL URLWithString:uri];

		vs->Asset = [[AVURLAsset alloc] initWithURL:url options:nil];
		[vs->Asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{

			dispatch_async(dispatch_get_main_queue(),^{

				uAutoReleasePool pool;
				NSError* error = nil;
				AVKeyValueStatus status = [vs->Asset statusOfValueForKey:@"tracks" error:&error];

				if (status == AVKeyValueStatusLoaded)
				{
					NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],(id)kCVPixelBufferPixelFormatTypeKey,nil];
					vs->PlayerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
					vs->PlayerItem = [[AVPlayerItem alloc] initWithAsset: vs->Asset];
					[vs->PlayerItem addOutput:vs->PlayerItemVideoOutput];
					vs->Player = [[AVPlayer alloc] initWithPlayerItem:vs->PlayerItem];

					vs->LoadedHandler = loadedCallback;
					vs->_presentationSizeObserver = [[PresentationSizeObserver alloc] init];
					[vs->Player addObserver: vs->_presentationSizeObserver
					             forKeyPath: @"currentItem.presentationSize"
					                options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
					                context: vs];

					[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
					if (errorCallback != NULL)
						uRelease(errorCallback);
				}
				else
				{
					if (loadedCallback != NULL)
						uRelease(loadedCallback);

					if (errorCallback != NULL)
					{
						@{Uno.Action:Of(errorCallback):Call()};
						uRelease(errorCallback);
					}
					NSLog(@"Failed to load the tracks.");
				}
			});
		}];
	}

	double getDuration(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		return CMTimeGetSeconds([vs->Asset duration]);
	}

	double getPosition(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		return CMTimeGetSeconds([vs->PlayerItem currentTime]);
	}

	void setPosition(void * videoState, double position)
	{
		VideoState * vs = (VideoState*)videoState;
		[vs->Player seekToTime: CMTimeMake(position * 1000, 1000)];
	}

	float getVolume(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		return [vs->Player volume];
	}

	void setVolume(void * videoState, float volume)
	{
		VideoState * vs = (VideoState*)videoState;
		[vs->Player setVolume: volume];
	}

	int getWidth(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		return vs->Width;
	}

	int getHeight(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		return vs->Height;
	}

	void play(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		[vs->Player play];
	}

	void pause(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		[vs->Player pause];
	}

	int updateTexture(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;

		if(![vs->PlayerItemVideoOutput hasNewPixelBufferForItemTime: [vs->PlayerItem currentTime]])
			return CVOpenGLESTextureGetName(vs->TextureHandle);

		CVPixelBufferRef pixelBuffer = [vs->PlayerItemVideoOutput copyPixelBufferForItemTime: [vs->PlayerItem currentTime] itemTimeForDisplay:nil];
		if(pixelBuffer == NULL)
			return CVOpenGLESTextureGetName(vs->TextureHandle);

		size_t width = CVPixelBufferGetWidth(pixelBuffer);
		size_t height = CVPixelBufferGetHeight(pixelBuffer);

		cleanup(videoState);

		glActiveTexture(GL_TEXTURE0);
		CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
			kCFAllocatorDefault,
			vs->TextureCacheHandle,
			pixelBuffer,
			NULL,
			GL_TEXTURE_2D,
			GL_RGBA,
			(GLsizei)width,
			(GLsizei)height,
			GL_BGRA_EXT,
			GL_UNSIGNED_BYTE,
			0,
			&vs->TextureHandle);

		if (err)
		{
			NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
			if (vs->ErrorHandler)
			{
				@{Uno.Action:Of(vs->ErrorHandler):Call()};
			}
		}

		glBindTexture(CVOpenGLESTextureGetTarget(vs->TextureHandle), CVOpenGLESTextureGetName(vs->TextureHandle));
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		CVBufferRelease(pixelBuffer);
		return CVOpenGLESTextureGetName(vs->TextureHandle);
	}

	int getRotation(void * videoState)
	{
		VideoState * vs = (VideoState*)videoState;
		auto degrees = 0;
		auto tracks = [vs->Asset tracks];
		for (auto i = 0; i < tracks.count; i++)
		{
			auto track = tracks[i];
			if ([track.mediaType isEqualToString:AVMediaTypeVideo])
			{
				auto t = track.preferredTransform;
				auto angle = atan2((double)t.b, (double)t.a);
				auto d = angle * 180.0 / M_PI;
				if (d < 0)
				{
					d = 360.0 + d;
				}
				degrees = (int)d;
				break;
			}
		}
		return degrees;
	}
}
