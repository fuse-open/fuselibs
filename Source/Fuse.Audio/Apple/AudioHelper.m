#ifdef iOS
#import "AudioHelper.h"
#else
#import "Apple/AudioHelper.h"
#endif

@implementation SoundHandle
{
	NSNumber* _identifier;
	AudioHelper* _helper;
}

@synthesize player;

static int _idPool = 0;
+(NSNumber*)getNextID
{
	return [[NSNumber alloc] initWithInt:_idPool++];
}

-(NSNumber*)getIdentifier
{
	return _identifier;
}

-(id) init:(NSData*)bytes helper:(AudioHelper*)helper
{
	self = [super init];
	_identifier = [SoundHandle getNextID];
	_helper = helper;
	self.player = [[AVAudioPlayer alloc] initWithData:bytes error:nil];
	[player setDelegate: self];
	[player prepareToPlay];

	return self;
}

-(id) initWithUrl:(NSURL*)url helper:(AudioHelper*)helper
{
	self = [super init];
	_identifier = [SoundHandle getNextID];
	_helper = helper;
	self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
	[player setDelegate: self];
	[player prepareToPlay];

	return self;
}

- (void)play
{
	[player play];
}

- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *) player
						successfully: (BOOL) completed
{
	if (completed)
    {
		self.player = nil;
		[_helper kill:self];
	}
}

@end

@implementation AudioHelper
{
	NSMutableDictionary* _playingSounds;
}

static AudioHelper* _instance;

+(AudioHelper*) getInstance
{
	if(_instance == nil) _instance = [[AudioHelper alloc] init];
	return _instance;
}

- (void)kill:(SoundHandle *)handle
{
	[_playingSounds removeObjectForKey:[handle getIdentifier]];
}

-(id)init
{
	self = [super init];
	_playingSounds = [[NSMutableDictionary alloc] init];
	return self;
}

- (NSNumber *)playSound:(NSData*)bytes
{
	SoundHandle* handle = [[SoundHandle alloc] init:bytes helper:self];
	_playingSounds[[handle getIdentifier]] = handle;
	[handle play];
	return [handle getIdentifier];
}

- (NSNumber *)playSoundFromFile:(NSURL*)url
{
	SoundHandle* handle = [[SoundHandle alloc] initWithUrl:url helper:self];
	_playingSounds[[handle getIdentifier]] = handle;
	[handle play];
	return [handle getIdentifier];
}

@end
