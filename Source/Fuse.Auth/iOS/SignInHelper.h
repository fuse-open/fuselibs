#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AuthenticationServices/AuthenticationServices.h>
#import <Security/Security.h>

@interface SignInHelper: NSObject<ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@property (nonatomic, copy) void (^_action_success)();
@property (nonatomic, copy) void (^_action_error)(NSString* error);

-(void)handleAppleIDAuthorization:(void (^)())action_success error: (void (^)(NSString*))action_error;

-(void)hasSignedIn:(void (^)(bool))result;

@end