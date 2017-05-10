#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "Actions.h"

@interface ImagePicker : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (atomic, copy) DictionaryAction onPicture;
@property (atomic, copy) Action onCancel;
-(UIViewController*) VC;
-(void) closePickerThen:(Action)a;

-(BOOL) openImagePickerWithSourceType:(UIImagePickerControllerSourceType)type 
		then:(DictionaryAction)a 
		or:(Action)b;
@end