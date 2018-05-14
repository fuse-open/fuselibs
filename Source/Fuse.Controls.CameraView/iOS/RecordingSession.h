#ifndef RECORDINGSESSION_H
#define RECORDINGSESSION_H

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface RecordingSession : NSObject<AVCaptureFileOutputRecordingDelegate>

-(instancetype)initWithMovieFileOutput:(AVCaptureMovieFileOutput*)movieFileOutput withCleanupHandler:(void(^)(NSURL*))handler withDispatchQueue:(dispatch_queue_t)queue;

-(void)stopRecording:(void(^)(NSString*))resolve onReject:(void(^)(NSString*))reject;

@end

#endif