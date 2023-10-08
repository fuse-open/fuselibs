using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.iOS
{
	extern(!iOS) public class GraphicsView
	{
		[UXConstructor]
		public GraphicsView([UXParameter("Host")]Visual host) { }
	}
	[extern(!METAL) Require("xcode.framework", "GLKit")]
	[Require("source.include", "UIKit/UIKit.h")]
	[extern(!METAL) Require("source.include", "GLKit/GLKit.h")]
	[extern(!METAL) Require("source.include", "OpenGLES/EAGL.h")]
	[extern(METAL) Require("source.include", "MetalANGLE/MGLKit.h")]
	[Require("source.include", "Context.h")]
	[Require("source.include", "iOS/ContainerView.h")]
	[Require("source.include", "iOS/Helpers.h")]
	extern(iOS) public class GraphicsView : View, IGraphicsView, IViewHost
	{

		void IViewHost.Insert(ViewHandle child)
		{
			new ViewHandle(_hitSurface).InsertChild(child);
		}

		void IViewHost.Remove(ViewHandle child)
		{
			new ViewHandle(_hitSurface).RemoveChild(child);
		}

		Visual _visual;

		ObjC.Object _glkViewHandle;
		ObjC.Object _hitSurface;

		[UXConstructor]
		public GraphicsView([UXParameter("Host")]Visual visual) : base(CreateContainer())
		{
			_glkViewHandle = CreateGlkView(NativeHandle);
			_hitSurface = CreateHitSurface(NativeHandle);
			_visual = visual;
		}

		public override ObjC.Object HitTestHandle
		{
			get { return _hitSurface; }
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateContainer()
		@{
			ContainerView* view = [[ContainerView alloc] init];
			[view viewDidLoad];
			return view;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateHitSurface(ObjC.Object container)
		@{
			UIView* c = (UIView*)container;
			UIControl* control = [[UIControl alloc] init];
			control.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			[[control layer] setAnchorPoint: { 0.0f, 0.0f }];
			[control setOpaque:false];
			[control setMultipleTouchEnabled:true];
			[c addSubview: control];
			[c bringSubviewToFront: control];
			return control;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateGlkView(ObjC.Object container)
		@{
			UIView* c = (UIView*)container;
		#if @(METAL:defined)
			MGLKView* view = [[MGLKView alloc] init];
		#else
			GLKView* view = [[GLKView alloc] init];
		#endif
			view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			[[view layer] setAnchorPoint: { 0.0f, 0.0f }];
			[view setBackgroundColor: [UIColor colorWithRed:0.0f green: 0.0f blue:0.0f alpha:0.0f]];
		#if @(METAL:defined)
			[view setDrawableDepthFormat:MGLDrawableDepthFormat16];
		#else
			[view setDrawableDepthFormat:GLKViewDrawableDepthFormat16];
		#endif
			[view setEnableSetNeedsDisplay:true];
			[view setMultipleTouchEnabled:true];
			[c addSubview: view];
			return view;
		@}

		bool IGraphicsView.BeginDraw(int2 size) { return BeginDraw(_glkViewHandle, size.X, size.Y); }

		void IGraphicsView.EndDraw() { EndDraw(_glkViewHandle); }

		[Foreign(Language.ObjC)]
		static bool BeginDraw(ObjC.Object handle, int x, int y)
		@{
			if (x < 1 || y < 1)
				return false;

		#if @(METAL:defined)
			MGLKView* glkView = (MGLKView*)handle;
			MGLContext* ctx = [[uContext sharedContext] glContext];
		#else
			GLKView* glkView = (GLKView*)handle;
			EAGLContext* ctx = [[uContext sharedContext] glContext];
		#endif

			[glkView setContext:ctx];
			[glkView bindDrawable];

			int w = (int)[glkView drawableWidth];
			int h = (int)[glkView drawableHeight];

			if (w < 1 || h < 1)
			{
				// throw or something
			}

			return true;
		@}

		[Foreign(Language.ObjC)]
		static void EndDraw(ObjC.Object handle)
		@{
		#if @(METAL:defined)
			MGLKView* glkView = (MGLKView*)handle;
		#else
			GLKView* glkView = (GLKView*)handle;
		#endif
			[glkView display];
		@}

		public override void Dispose()
		{
			_visual = null;
			DeleteDrawable(_glkViewHandle);
			_hitSurface = null;
			_glkViewHandle = null;
			base.Dispose();
		}

		[Foreign(Language.ObjC)]
		static void DeleteDrawable(ObjC.Object handle)
		@{
		#if @(METAL:defined)
			MGLKView* glkView = (MGLKView*)handle;

			// FIXME: No deleteDrawable method in MGLKView?
		#else
			GLKView* glkView = (GLKView*)handle;

			[glkView deleteDrawable];
		#endif
		@}

	}
}
