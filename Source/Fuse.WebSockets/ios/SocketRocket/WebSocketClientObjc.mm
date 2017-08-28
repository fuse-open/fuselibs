#import "ios/SocketRocket/WebSocketClientObjc.h"
#import "SRWebSocket.h"

@interface WebSocketClientObjc () <SRWebSocketDelegate>

	@property NSURL *url;
	@property (nonatomic, copy) void (^eventHandler)(NSString *, NSString *);
	@property (nonatomic, copy) void (^receivedMessage)(NSString *);
	@property (nonatomic, copy) void (^receivedData)(uint8_t *, NSUInteger);
	
	@property SRWebSocket *webSocket;

@end

@implementation WebSocketClientObjc
- (instancetype)initWithUrl:(NSString *)url
				protocols:(NSArray*)protocols
				eventHandler:(void (^)(NSString *, NSString *))eventHandler
				onReceivedMessage:(void (^)(NSString *))receivedMessage
				onReceivedData:(void (^)(uint8_t *, NSUInteger))receivedData {
	self = [super init];
	if (self != nil) {
		self.url = [NSURL URLWithString:url];
		self.eventHandler = eventHandler;
		self.receivedMessage = receivedMessage;
		self.receivedData = receivedData;
		self.webSocket = [[SRWebSocket alloc] initWithURL:self.url protocols:protocols];
		self.webSocket.delegate = self;
	}
	return self;
}

- (void)sendString:(NSString *)data {
	[self.webSocket send:data];
}

- (void)sendData:(const uint8_t *)data length:(NSUInteger)length {
	[self.webSocket send:[NSData dataWithBytes: data length: sizeof(unsigned char) * length]];
}

- (void)connect {
	[self.webSocket open];
}

- (void)disconnect {
	[self.webSocket close];
}

- (void)setHeaderKey:(NSString *)key withValue:(NSString *)value {
	//TODO: [self.webSocket addHeader:key forKey:value];
}

///--------------------------------------
#pragma mark - SRWebSocketDelegate
///--------------------------------------

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
	self.eventHandler(@"open", nil);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
	self.eventHandler(@"error", [error localizedDescription]);
	self.eventHandler(@"close", [error localizedDescription]);
	_webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
	if ([message isKindOfClass:[NSString class]])
		self.receivedMessage(message);
	else if ([message isKindOfClass:[NSData class]]) {
		NSData *data = (NSData *)message;
		self.receivedData((uint8_t *)[data bytes], [data length]);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
	self.eventHandler(@"close", reason);
	_webSocket = nil;
}

@end
