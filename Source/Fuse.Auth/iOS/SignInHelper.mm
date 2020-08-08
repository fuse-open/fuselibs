#import "SignInHelper.h"

@implementation SignInHelper


-(void)handleAppleIDAuthorization:(void (^)())action_success error: (void (^)(NSString*))action_error;
{

    if (@available(iOS 13.0, *)) {
        self._action_success = action_success;
        self._action_error = action_error;

        ASAuthorizationAppleIDProvider *appleIDProvider = [ASAuthorizationAppleIDProvider new];
        ASAuthorizationAppleIDRequest *request = appleIDProvider.createRequest;
        request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
        ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
        controller.delegate = self;
        controller.presentationContextProvider = self;
        [controller performRequests];
    }
}

-(void)hasSignedIn:(void (^)(bool))result
{
    if (@available(iOS 13.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ASAuthorizationAppleIDProvider *appleIDProvider = [ASAuthorizationAppleIDProvider new];
            NSString* userId= [[NSUserDefaults standardUserDefaults] valueForKey:@"appleIDCredential.currentIdentifier"];
            if (userId == nil)
            {
                result(false);
                return;
            }
            [appleIDProvider getCredentialStateForUserID:userId
                completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState, NSError *error) {
                    switch(credentialState)
                    {
                        case ASAuthorizationAppleIDProviderCredentialAuthorized:
                            result(true);
                            break;
                        case ASAuthorizationAppleIDProviderCredentialNotFound:
                        case ASAuthorizationAppleIDProviderCredentialRevoked:
                            // remove appleId / password credential Information
                            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"platformSignIn.userId"];
                            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"platformSignIn.lastName"];
                            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"platformSignIn.firstName"];
                            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"platformSignIn.email"];

                            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"platformSignIn.user"];
                            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"platformSignIn.password"];
                            result(false);
                            break;
                        default:
                            result(false);
                            break;
                    }
            }];
        });
    }
    result(false);
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error
{
    self._action_error(error.localizedDescription);
}

-(void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization
{
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
        ASAuthorizationAppleIDCredential *appleIDCredential = authorization.credential;
        NSString *user = appleIDCredential.user;
        NSString *familyName = appleIDCredential.fullName.familyName;
        NSString *givenName = appleIDCredential.fullName.givenName;
        NSString *email = appleIDCredential.email;
        // save to UserDefaults
        if (user != nil)
            [[NSUserDefaults standardUserDefaults] setValue:user forKey:@"platformSignIn.userId"];
        if (familyName != nil)
            [[NSUserDefaults standardUserDefaults] setValue:familyName forKey:@"platformSignIn.lastName"];
        if (givenName != nil)
            [[NSUserDefaults standardUserDefaults] setValue:givenName forKey:@"platformSignIn.firstName"];
        if (email != nil)
            [[NSUserDefaults standardUserDefaults] setValue:email forKey:@"platformSignIn.email"];

        if (self._action_success != nil)
            self._action_success();
    }
    if ([authorization.credential isKindOfClass:[ASPasswordCredential class]]) {
        ASPasswordCredential *passwordCredential = authorization.credential;
        NSString *user = passwordCredential.user;
        NSString *password = passwordCredential.password;

        if (user != nil)
            [[NSUserDefaults standardUserDefaults] setValue:user forKey:@"platformSignIn.user"];
        if (password != nil)
            [[NSUserDefaults standardUserDefaults] setValue:password forKey:@"platformSignIn.password"];

        if (self._action_success != nil)
            self._action_success();
    }
}

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller  API_AVAILABLE(ios(13.0)){

    return [[UIApplication sharedApplication] delegate].window;
}


@end