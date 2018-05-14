using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse.Elements;

namespace Fuse.Controls
{
	public interface IPhotoPreviewHost
	{
		void OnPhotoLoaded();
	}

	public interface IPhotoPreview
	{
		PreviewStretchMode PreviewStretchMode { set; }
	}

	public abstract class PhotoPreviewBase : Panel, IPhotoPreviewHost
	{
		PreviewStretchMode _previewStretchMode;
		public PreviewStretchMode PreviewStretchMode
		{
			get { return _previewStretchMode; }
			set
			{
				if (_previewStretchMode != value)
				{
					_previewStretchMode = value;
					OnPreviewStretchModeChanged();
				}
			}
		}

		public event EventHandler PhotoLoaded;

		protected void OnPhotoLoaded()
		{
			var handler = PhotoLoaded;
			if (handler != null)
				handler(this, EventArgs.Empty);
		}

		void IPhotoPreviewHost.OnPhotoLoaded()
		{
			OnPhotoLoaded();
		}

		IPhotoPreview PhotoPreview
		{
			get { return ViewHandle as IPhotoPreview; }
		}

		protected override void PushPropertiesToNativeView()
		{
			base.PushPropertiesToNativeView();
			OnPreviewStretchModeChanged();
		}

		void OnPreviewStretchModeChanged()
		{
			var pp = PhotoPreview;
			if (pp != null)
				pp.PreviewStretchMode = PreviewStretchMode;
		}
	}
}
