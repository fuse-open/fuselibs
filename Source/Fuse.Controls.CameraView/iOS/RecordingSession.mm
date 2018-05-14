#include "RecordingSession.h"

@interface RecordingSession () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic,strong) AVCaptureMovieFileOutput* movieFileOutput;
@property (nonatomic,strong) void(^cleanupHandler)(NSURL*);

@property (copy) void(^onResolve)(NSString*);
@property (copy) void(^onReject)(NSString*);

@property (nonatomic) BOOL stopped;

@property (nonatomic,strong) dispatch_queue_t queue;

@end

@implementation RecordingSession

-(instancetype)initWithMovieFileOutput:(AVCaptureMovieFileOutput*)movieFileOutput withCleanupHandler:(void(^)(NSURL*))handler withDispatchQueue:(dispatch_queue_t)queue {
	if (self = [super init]) {
		self.movieFileOutput = movieFileOutput;
		self.cleanupHandler = handler;
		self.queue = queue;
		self.stopped = false;
	}
	return self;
}

-(void)stopRecording:(void(^)(NSString*))resolve onReject:(void(^)(NSString*))reject {
	if (!self.stopped) {
		self.stopped = true;
		self.onResolve = resolve;
		self.onReject = reject;
		dispatch_async(self.queue, ^{
			[self.movieFileOutput stopRecording];
		});
	} else {
		reject(@"RecordingSession already stopped!");
	}
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {

	dispatch_block_t cleanup = ^{
		self.cleanupHandler(outputFileURL);
	};

	BOOL success = YES;

	if (error) {
		NSLog( @"Movie file finishing error: %@", error );
		success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
	}

	if (success) {
		NSString* sourcePath = outputFileURL.path;
		NSString* fileName = [sourcePath lastPathComponent];
		NSString* destinationDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		NSString* desitnationPath = [NSString stringWithFormat:@"%@/%@", destinationDir, fileName];
		NSError* error = NULL;
		if (![[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:desitnationPath error:&error]) {
			cleanup();
			self.onReject([NSString stringWithFormat:@"Failed to move captured output: %@", error]);
		} else {
			cleanup();
			self.onResolve(desitnationPath);
		}
	} else {
		cleanup();
		self.onReject([NSString stringWithFormat:@"Failed to capture output: %@", error]);
	}
}

@end