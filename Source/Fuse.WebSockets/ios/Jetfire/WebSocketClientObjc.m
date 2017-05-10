
#import "ios/Jetfire/WebSocketClientObjc.h"
@import Jetfire;

@interface WebSocketClientObjc () <JFRWebSocketDelegate>

	@property NSURL *url;
	@property (nonatomic, copy) void (^eventHandler)(NSString *, NSString *);
	@property (nonatomic, copy) void (^receivedMessage)(NSString *);
	@property (nonatomic, copy) void (^receivedData)(uint8_t *, NSUInteger);
	@property JFRWebSocket *webSocket;

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
		self.webSocket = [[JFRWebSocket alloc] initWithURL:self.url protocols:protocols];
		self.webSocket.delegate = self;
	}
	return self;
}

- (void)sendString:(NSString *)data {
	[self.webSocket writeString:data];
}

- (void)sendData:(const uint8_t *)data length:(NSUInteger)length {
	[self.webSocket writeData:[NSData dataWithBytes: data length: sizeof(unsigned char) * length]];
}

- (void)connect {
	[self.webSocket connect];
}

- (void)disconnect {
	if (self.webSocket.isConnected) {
		[self.webSocket disconnect];
	}
}

- (void)setHeaderKey:(NSString *)key withValue:(NSString *)value {
	[self.webSocket addHeader:key forKey:value];
}

#pragma mark - JFRWebSocketDelegate

- (void)websocketDidConnect:(JFRWebSocket*)webSocket {
	self.eventHandler(@"open", nil);
}

- (void)websocketDidDisconnect:(JFRWebSocket*)webSocket error:(NSError*)error {
	self.eventHandler(@"error", [error localizedDescription]);
	self.eventHandler(@"close", [error localizedDescription]);
}

- (void)websocket:(JFRWebSocket*)webSocket didReceiveMessage:(NSString*)message {
	self.receivedMessage(message);
}

- (void)websocket:(JFRWebSocket*)webSocket didReceiveData:(NSData*)data {
	self.receivedData((uint8_t *)[data bytes], [data length]);
}

@end
