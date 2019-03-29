#pragma once

#if !(@{Fuse.Controls.Native.iOS.GraphicsView:IsStripped} && @{Fuse.Controls.Native.iOS.FocusHelpers:IsStripped} && @{Fuse.Controls.Native.iOS.InputDispatch:IsStripped} && @{Fuse.Controls.Native.iOS.KeyboardView:IsStripped} && @{Fuse.Controls.Native.iOS.ScrollView:IsStripped} && @{Fuse.Controls.Native.iOS.SingleLineTextEdit:IsStripped} && @{Fuse.Controls.Native.iOS.MultiLineTextEdit:IsStripped} && @{Fuse.Controls.Native.iOS.UIControlEvent:IsStripped})

#include <Uno/Uno.h>
#include <UIKit/UIKit.h>
#include <GLKit/GLKit.h>
#include <OpenGLES/EAGL.h>

@interface ShapeView : UIControl
-(UIControl*)childrenView;
-(UIControl*)shapeView;
@end

@interface KeyboardView : UIControl<UIKeyInput>

@property(nonatomic) bool isFocusable;
@property(nonatomic) UIReturnKeyType returnKeyType;
@property(nonatomic) UIKeyboardType keyboardType;

@end

@interface SizeControl : UIControl

@property (copy) void (^onSetFrameCallback)(id);

@end

@interface UIResponder (FirstResponder)

+(id)currentFirstResponder;
-(void)findFirstResponder:(id)sender;

@end

@interface TextFieldDelegate : NSObject<UITextFieldDelegate>

@property (copy) bool (^onActionCallback)(id);
- (BOOL)textFieldShouldReturn:(UITextField *)textField;

@property int maxLength;
- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
	replacementString:(NSString *)string;

@property (copy) bool (^shouldEditingCallback)(id);
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;

@end

@interface TextViewDelegate : NSObject<UITextViewDelegate>

@property (copy) void (^textChangedCallback)(id);
@property (copy) void (^didBeginEditingCallback)();
- (void)textViewDidBeginEditing:(UITextView *)textView;
- (void)textViewDidChange:(UITextView *)textView;
- (void)textViewDidEndEditing:(UITextView *)textView;

@property int maxLength;
- (BOOL)textView:(UITextView *)textView
	shouldChangeTextInRange:(NSRange)range
	replacementText:(NSString *)text;

@end

@interface ScrollViewDelegate : NSObject<UIScrollViewDelegate>

@property (copy) void (^didScrollCallback)(id);
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

@end

@interface UIControlEventHandler : NSObject { }
- (void)action:(id)sender forEvent:(UIEvent *)event;
@property (copy) void (^callback)(id, id);
@end

#endif // IsStripped
