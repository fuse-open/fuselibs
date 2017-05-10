#import "ImageHelper.h"


@implementation ImageHelper

+(UIImage*) imageFromDictionary:(NSDictionary*)dictionary {
	return dictionary[@"UIImagePickerControllerOriginalImage"];
}

+(NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
		  case 0xFF:
		      return @"jpg";
		  case 0x89:
		      return @"png";
			default:
					return nil;
    }
}

+(NSString*)imageFromDataSync:(NSData*)data {
	@try {
		NSString* extension = [self contentTypeForImageData:data];
		if(extension==nil)
			[NSException raise:@"InvalidImageFormat" format:@"Invalid image format"];

		UIImage* newImage = [UIImage imageWithData:data];
		NSString* path = [self createImagePathWithExtension:extension temp:YES];
		[self saveImage:newImage path:path];
		return path;
	}
	@catch (NSException* e) {
		return nil;
	}
}

+(void)imageFromData:(NSData*)data onComplete:(StringAction)onComplete onFail:(StringAction)onFail
{
	@try {
		NSString* extension = [self contentTypeForImageData:data];
		if(extension==nil)
			[NSException raise:@"InvalidImageFormat" format:@"Invalid image format"];

		UIImage* newImage = [UIImage imageWithData:data];
		NSString* path = [self createImagePathWithExtension:extension temp:YES];
		[self saveImage:newImage path:path];
		onComplete(path);
	}
	@catch (NSException* e) {
		onFail([NSString stringWithFormat:@"Image load error: %@", e]);
	}
}

+(void)saveImage:(UIImage*)image path:(NSString*)path
{
	@autoreleasepool {
		NSData* imageData;
		NSString* ext = [[path pathExtension] lowercaseString];
		if([ext isEqualToString:@"png"]) {
			imageData = UIImagePNGRepresentation(image);
		} else {
			imageData = UIImageJPEGRepresentation(image, 0.9f);
		}

		[imageData writeToFile:path atomically:NO];
	}
}

+(NSArray*) getImageSize:(NSString*)path {
	CGFloat width = 0.0f, height = 0.0f;
	NSURL *imageFileURL = [NSURL fileURLWithPath:path];
	CFURLRef url = (__bridge CFURLRef) imageFileURL;
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL(url, nil);
	if (imageSource == nil) {
		return @[ @( 0 ), @( 0 )];
	}

	CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);

	CFRelease(imageSource);

	if (imageProperties != nil) {

		CFNumberRef widthNum  = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
		if (widthNum != nil) {
			CFNumberGetValue(widthNum, kCFNumberCGFloatType, &width);
		}

		CFNumberRef heightNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
		if (heightNum != nil) {
			CFNumberGetValue(heightNum, kCFNumberCGFloatType, &height);
		}

		CFRelease(imageProperties);
	}

	return @[ @( (int)width ), @( (int)height )]; //Weird spacing here to avoid uxl expansion issues
}

+(UIImage*) correctImageOrientation:(UIImage*)image {
	if (image.imageOrientation == UIImageOrientationUp) return image;
	CGAffineTransform transform = CGAffineTransformIdentity;

	switch (image.imageOrientation) {
		case UIImageOrientationDown:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
			transform = CGAffineTransformRotate(transform, (CGFloat) M_PI);
			break;

		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
			transform = CGAffineTransformTranslate(transform, image.size.width, 0);
			transform = CGAffineTransformRotate(transform, (CGFloat) M_PI_2);
			break;

		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, 0, image.size.height);
			transform = CGAffineTransformRotate(transform, (CGFloat) -M_PI_2);
			break;
		case UIImageOrientationUp:
		case UIImageOrientationUpMirrored:
			break;
	}

	switch (image.imageOrientation) {
		case UIImageOrientationUpMirrored:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, image.size.width, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;

		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, image.size.height, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
		case UIImageOrientationUp:
		case UIImageOrientationDown:
		case UIImageOrientationLeft:
		case UIImageOrientationRight:
			break;
	}

	CGContextRef ctx = CGBitmapContextCreate(nil, (size_t) image.size.width, (size_t) image.size.height,
			CGImageGetBitsPerComponent(image.CGImage), 0,
			CGImageGetColorSpace(image.CGImage),
			CGImageGetBitmapInfo(image.CGImage));
	CGContextConcatCTM(ctx, transform);
	switch (image.imageOrientation) {
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			// Grr...
			CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
			break;

		default:
			CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
			break;
	}

	CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
	UIImage *img = [UIImage imageWithCGImage:cgimg];
	CGContextRelease(ctx);
	CGImageRelease(cgimg);
	return img;
}

+(void)cropImage:(NSString*)path
		desiredRect:(CGRect)rect
		onComplete:(StringAction)onComplete
		onFail:(StringAction)onFail
		performInPlace:(BOOL)inPlace
{
	@try
	{
		UIImage* newImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([[UIImage imageWithContentsOfFile:path] CGImage], rect)];
		if(!inPlace)
			path = [self createImagePath:YES];

		[self saveImage:newImage path:path];
		onComplete(path);
	}
	@catch (NSException* e)
	{
		onFail([NSString stringWithFormat:@"Image crop error: %@", e]);
	}
}


+(void)resizeImage:(NSString*)path
		width:(float)desiredWidth
		height:(float)desiredHeight
		mode:(int)mode
		onComplete:(StringAction)onComplete
		onFail:(StringAction)onFail
		performInPlace:(BOOL)inPlace
{

	@try {

		UIImage* image = [UIImage imageWithContentsOfFile:path];
		CGSize currentSize = [image size];
		float width = currentSize.width;
		float height = currentSize.height;
		float ratio;

		UIImage *newImage = nil;

		CGRect cropRect;

		if (width > desiredWidth || height > desiredHeight)
		{
			switch(mode){
				case 1:
					//Keep aspect
					if (width > desiredWidth) {
						ratio = desiredWidth / width;
						width *= ratio;
						height *= ratio;
					}
					if (height > desiredHeight) {
						ratio = desiredHeight / height;
						width *= ratio;
						height *= ratio;
					}

					UIGraphicsBeginImageContextWithOptions(CGSizeMake(width,height), NO, 1.0);
					[image drawInRect:CGRectMake(0, 0, width, height)];
					newImage = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
					break;
				case 2:
					//resize to closest with aspect correction, then crop with centered rect
					if (width > height) {
						if (height > desiredHeight)
						{
							ratio = desiredHeight / height;
							width *= ratio;
							height *= ratio;
						}else if (width > desiredWidth)
						{
							ratio = desiredWidth / width;
							width *= ratio;
							height *= ratio;
						}
					} else {
						if (width > desiredWidth)
						{
							ratio = desiredWidth / width;
							width *= ratio;
							height *= ratio;
						}
						else if (height > desiredHeight)
						{
							ratio = desiredHeight / height;
							width *= ratio;
							height *= ratio;
						}
					}

					UIGraphicsBeginImageContextWithOptions(CGSizeMake(width,height), NO, 1.0);
					[image drawInRect:CGRectMake(0, 0, width, height)];
					newImage = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();


					cropRect = CGRectMake(
							MAX(0, width/2 - desiredWidth/2),
							MAX(0, height/2 - desiredHeight/2),
							MIN(desiredWidth, width),
							MIN(desiredHeight, height));

					@autoreleasepool {
						struct CGImage* cgimage = CGImageCreateWithImageInRect([newImage CGImage], cropRect);
						newImage = [UIImage imageWithCGImage:cgimage];
						CGImageRelease(cgimage);
					}
					break;
				default:
					//Use width/height as given
					UIGraphicsBeginImageContextWithOptions(CGSizeMake(desiredWidth, desiredHeight), NO, 1.0);
					[image drawInRect:CGRectMake(0, 0, desiredWidth, desiredHeight)];
					newImage = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
			}
			//Save the final image
			if(!inPlace)
				path = [self createImagePath:YES];

			[self saveImage:newImage path:path];
			onComplete(path);
		}else
		{
			//No resizing necessary
			onComplete(path);
		}
	}@catch (NSException * e){
		onFail([NSString stringWithFormat:@"Image resize error: %@", e]);
	}
}

+(void) imageFromBase64String:(NSString*)b64
		onComplete:(StringAction)a
		onFail:(StringAction)b
{
	@try {
		NSData* data = [[NSData alloc] initWithBase64EncodedString:b64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
		UIImage* image = [UIImage imageWithData:data];
		NSString* path = [self createImagePathWithExtension:@"jpg" temp:YES];
		[self saveImage:image path:path];
		a(path);
	} @catch(NSException* e) {
		b(@"Could not decode image");
	}
}
+(void) base64FromImageAtPath:(NSString*)path
		onComplete:(StringAction)a
		onFail:(StringAction)b
{
	UIImage* img = [UIImage imageWithContentsOfFile:path];
	@try {
		NSString* b64 = [UIImageJPEGRepresentation(img, 0.9f) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
		a(b64);
	}@catch(NSException* e){
		b(@"Could not encode image");
	}
}

+(NSString*) createImagePath:(BOOL)temp
{
	NSString* p = [NSString stringWithFormat:@"%@images", temp?[self applicationTempDirectory]:[self applicationDocumentsDirectory]];
	NSError * error = nil;
	[[NSFileManager defaultManager] createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:&error];
	if (error != nil) {
		NSLog(@"error creating directory: %@", error);
	}
	return p;
}

+(NSString*) createImagePathWithExtension:(NSString*)extension
		temp:(BOOL)temp
{
	NSString *uuid = [[NSUUID UUID] UUIDString];
	return [NSString stringWithFormat:@"%@/IMG_%@.%@", [self createImagePath:temp], uuid, extension];
}

+(NSString*) localPathFromPHImageFileURL:(NSURL*)url
		temp:(BOOL)temp
{
	NSString* name = [[url path] lastPathComponent];
	return [NSString stringWithFormat:@"%@/%@", [self createImagePath:temp], name];
}

+(NSString*) applicationDocumentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *basePath = paths.firstObject;
	return basePath;
}

+(NSString*) applicationTempDirectory {
	return NSTemporaryDirectory();
}
@end
