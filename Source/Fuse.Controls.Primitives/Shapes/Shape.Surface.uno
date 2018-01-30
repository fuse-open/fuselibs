using Uno;
using Uno.Collections;

using Fuse.Drawing;

namespace Fuse.Controls
{
	public abstract partial class Shape
	{
		virtual protected bool NeedSurface { get { return true; } }
		
		bool _surfacePathDirty;
		SurfacePath _surfacePath;
		
		protected virtual void OnSurfaceRooted()
		{
			_watcher = new DrawObjectWatcher();
			_watcher.OnRooted(this);
		}
		
		protected virtual void OnSurfaceUnrooted()
		{
			if (_surfacePath != null)
			{
				Surface.DisposePath(_surfacePath);
				_surfacePath = null;
			}
			
			_watcher.OnUnrooted();
			//no need to clear _watcher, we'll likely need it again next time rooted
			SurfaceManager.Release(this, _surface);
			_surface = null;
		}

		/**
			Indicates the rendering shape needs to change as one or more properties has changed.
			
			This should be used even in non-surface mode. It will invalidate the visual.
		*/
		protected virtual void InvalidateSurfacePath()
		{
			_surfacePathDirty = true;
			InvalidateVisual();
		}
		
		void IDrawObjectWatcherFeedback.Changed(object obj)
		{
			if (obj is Stroke)
				InvalidateLayout(); //TODO: optimize, since only `Path` needs a Layout invalidation, and only sometimes
			InvalidateVisual();
		}
		
		void IDrawObjectWatcherFeedback.Prepare(object obj)
		{
			if (_surface == null)
			{
				Fuse.Diagnostics.InternalError( "Prepare without surface", this );
				return;
			}
			
			var b = obj as Brush;
			if (b != null)
				_surface.Prepare(b);
		}
		
		void IDrawObjectWatcherFeedback.Unprepare(object obj)
		{
			if (_surface == null)
			{
				Fuse.Diagnostics.InternalError( "Prepare without surface", this );
				return;
			}
			
			var b = obj as Brush;
			if (b != null)
				_surface.Unprepare(b);
		}
		
		void ISurfaceDrawable.Draw(Surface surface)
		{
			Watcher.Reset();
			//TODO: convert to indexed loop, also other places in Shape
			if (HasFills)
			{
				foreach (var fill in Fills)
					Watcher.Add(fill);
			}
			if (HasStrokes)
			{
				foreach (var stroke in Strokes)
					Watcher.Add(stroke);
			}
			Watcher.Sync();
			
			var path = GetSurfacePath(surface);
			if (HasFills)
			{
				foreach (var fill in Fills)
					surface.FillPath(path, fill);
			}
			
			if (HasStrokes)
			{
				foreach (var stroke in Strokes)
					surface.StrokePath(path,stroke);
			}
		}
		
		bool ISurfaceDrawable.IsPrimary { get { return NeedSurface; } }
		float2 ISurfaceDrawable.ElementSize { get { return ActualSize; } }
		
		protected SurfacePath GetSurfacePath(Surface surface)
		{
			if (!_surfacePathDirty && _surfacePath != null)
				return _surfacePath;
				
			if (_surfacePath != null)
				surface.DisposePath(_surfacePath);
				
			_surfacePath = CreateSurfacePath(surface);
			_surfacePathDirty = false;
			return _surfacePath;
		}
		
		/** Creates the path used to draw this shape in a  Surface.*/
		protected abstract SurfacePath CreateSurfacePath(Surface surface);
	}
}