#import "ImagePicker.h"

@implementation ImagePicker
{
	UIImagePickerController* _imagePicker;
}

-(UIViewController*) VC
{
	return [[[UIApplication sharedApplication] keyWindow] rootViewController];
}

-(BOOL)openImagePickerWithSourceType:(UIImagePickerControllerSourceType)type then:(DictionaryAction)a or:(Action)or
{
	if([UIImagePickerController isSourceTypeAvailable:type])
	{
		self.onPicture = a;
		self.onCancel = or;
		_imagePicker = [[UIImagePickerController alloc] init];
		_imagePicker.sourceType = type;
		[_imagePicker setDelegate:self];
		[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
			[[self VC] presentViewController:_imagePicker animated:YES completion:^{ }];
		}];
		return YES;
	}else{
		return NO;
	}
}

-(void) cleanUp
{
	self.onPicture = nil;
	self.onCancel = nil;
	_imagePicker = nil;
}

-(void)closePickerThen:(Action)a
{
	__block Action postAction = a;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		[[self VC] dismissViewControllerAnimated:YES completion:^{
			postAction();
			[self cleanUp];
		}];
	}];
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[self closePickerThen:^{
		self.onPicture(info);
	}];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self closePickerThen:self.onCancel];
}

@end
