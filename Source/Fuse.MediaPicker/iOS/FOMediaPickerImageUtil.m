#import "FOMediaPickerImageUtil.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface GIFInfo ()

@property(strong, nonatomic, readwrite) NSArray<UIImage *> *images;
@property(assign, nonatomic, readwrite) NSTimeInterval interval;

@end

@implementation GIFInfo

- (instancetype)initWithImages:(NSArray<UIImage *> *)images interval:(NSTimeInterval)interval;
{
	self = [super init];
	if (self) {
		self.images = images;
		self.interval = interval;
	}
	return self;
}

@end

@implementation FOMediaPickerImageUtil : NSObject

+ (UIImage *)scaledImage:(UIImage *)image
								maxWidth:(NSNumber *)maxWidth
							 maxHeight:(NSNumber *)maxHeight
							isMetadataAvailable:(BOOL)isMetadataAvailable {
	double originalWidth = image.size.width;
	double originalHeight = image.size.height;

	bool hasMaxWidth = maxWidth != (id)[NSNull null];
	bool hasMaxHeight = maxHeight != (id)[NSNull null];

	double width = hasMaxWidth ? MIN([maxWidth doubleValue], originalWidth) : originalWidth;
	double height = hasMaxHeight ? MIN([maxHeight doubleValue], originalHeight) : originalHeight;

	bool shouldDownscaleWidth = hasMaxWidth && [maxWidth doubleValue] < originalWidth;
	bool shouldDownscaleHeight = hasMaxHeight && [maxHeight doubleValue] < originalHeight;
	bool shouldDownscale = shouldDownscaleWidth || shouldDownscaleHeight;

	if (shouldDownscale) {
		double downscaledWidth = floor((height / originalHeight) * originalWidth);
		double downscaledHeight = floor((width / originalWidth) * originalHeight);

		if (width < height) {
			if (!hasMaxWidth) {
				width = downscaledWidth;
			} else {
				height = downscaledHeight;
			}
		} else if (height < width) {
			if (!hasMaxHeight) {
				height = downscaledHeight;
			} else {
				width = downscaledWidth;
			}
		} else {
			if (originalWidth < originalHeight) {
				width = downscaledWidth;
			} else if (originalHeight < originalWidth) {
				height = downscaledHeight;
			}
		}
	}

	if (!isMetadataAvailable) {
		UIImage *imageToScale = [UIImage imageWithCGImage:image.CGImage scale:1 orientation:image.imageOrientation];

		UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
		[imageToScale drawInRect:CGRectMake(0, 0, width, height)];

		UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		return scaledImage;
	}

	UIImage *imageToScale = [UIImage imageWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationUp];

	if ([image imageOrientation] == UIImageOrientationLeft ||
			[image imageOrientation] == UIImageOrientationRight ||
			[image imageOrientation] == UIImageOrientationLeftMirrored ||
			[image imageOrientation] == UIImageOrientationRightMirrored) {
		double temp = width;
		width = height;
		height = temp;
	}

	UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0);
	[imageToScale drawInRect:CGRectMake(0, 0, width, height)];

	UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return scaledImage;
}

@end
