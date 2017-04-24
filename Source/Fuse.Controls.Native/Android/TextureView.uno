using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native.Android
{
	extern(!Android) public class TextureView : GraphicsViewBase { }
	extern(Android) public class TextureView : GraphicsViewBase
	{
		public TextureView() : base(Create())
		{
			InstallSurfaceListener(GraphicsViewHandle);
		}

		void OnSurfaceTextureAvailable(Java.Object surface)
		{
			SetSurface(surface);
		}

		void OnSurfaceTextureDestroyed()
		{
			DestroySurface();
		}

		[Foreign(Language.Java)]
		void InstallSurfaceListener(Java.Object handle)
		@{
			((android.view.TextureView)handle).setSurfaceTextureListener(new android.view.TextureView.SurfaceTextureListener() {
				public void onSurfaceTextureAvailable(android.graphics.SurfaceTexture surface, int width, int height) {
					@{global::Fuse.Controls.Native.Android.TextureView:Of(_this).OnSurfaceTextureAvailable(Java.Object):Call(new android.view.Surface(surface))};
				}
				public boolean onSurfaceTextureDestroyed(android.graphics.SurfaceTexture surface) {
					@{global::Fuse.Controls.Native.Android.TextureView:Of(_this).OnSurfaceTextureDestroyed():Call()};
					return true;
				}
				public void onSurfaceTextureSizeChanged(android.graphics.SurfaceTexture surface, int width, int height) {

				}
				public void onSurfaceTextureUpdated(android.graphics.SurfaceTexture surface) {

				}
			});
		@}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			android.view.TextureView textureView = new android.view.TextureView(com.fuse.Activity.getRootActivity());
			textureView.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.FILL_PARENT, android.view.ViewGroup.LayoutParams.FILL_PARENT));
			return textureView;
		@}
	}
}