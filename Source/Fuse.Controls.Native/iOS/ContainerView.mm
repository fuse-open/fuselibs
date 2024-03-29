#import "ContainerView.h"
#import "uObjC.Foreign.h"
@{Fuse.Controls.Native.iOS.DarkMode:includeDirective}

@implementation ContainerView

- (void) viewDidLoad {
	#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.0")) {

		switch(self.traitCollection.userInterfaceStyle) {
			case UIUserInterfaceStyleUnspecified:
				@{Fuse.Controls.Native.iOS.DarkMode.changeDarkMode(string):call(@"Unspecified")};
				break;
			case UIUserInterfaceStyleLight:
				@{Fuse.Controls.Native.iOS.DarkMode.changeDarkMode(string):call(@"Light")};
				break;
			case UIUserInterfaceStyleDark:
				@{Fuse.Controls.Native.iOS.DarkMode.changeDarkMode(string):call(@"Dark")};
				break;
		}
	}
	#endif
}

- (void) traitCollectionDidChange: (UITraitCollection *) previousTraitCollection {

	[super traitCollectionDidChange: previousTraitCollection];

	#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0

	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.0")) {

		switch(self.traitCollection.userInterfaceStyle) {
			case UIUserInterfaceStyleUnspecified:
				@{Fuse.Controls.Native.iOS.DarkMode.changeDarkMode(string):call(@"Unspecified")};
				break;
			case UIUserInterfaceStyleLight:
				@{Fuse.Controls.Native.iOS.DarkMode.changeDarkMode(string):call(@"Light")};
				break;
			case UIUserInterfaceStyleDark:
				@{Fuse.Controls.Native.iOS.DarkMode.changeDarkMode(string):call(@"Dark")};
				break;
		}
	}
	#endif

}

@end