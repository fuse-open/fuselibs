using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Layouts;
using Fuse.Elements;

namespace Fuse.Controls
{
	/** Keep all data for the surface separate to avoid wasted memory in LayoutControl */
	class LayoutControlSurface : IDrawObjectWatcherFeedback
	{
		public bool WarnDraw;
		public SurfacePath BackgroundPath;
		public float2 BackgroundPathSize;
		public Surface Surface;
		public DrawObjectWatcher Watcher;
		public LayoutControl LayoutControl;
		
		//TODO: The below is essentially identical to that in Shape.Surface, maybe this can 
		//be mostly moved into the Watcher?
		void IDrawObjectWatcherFeedback.Changed(object obj)
		{
			if (obj is Stroke)
				LayoutControl.InvalidateLayout();
			LayoutControl.InvalidateVisual();
		}
		
		void IDrawObjectWatcherFeedback.Prepare(object obj)
		{
			if (Surface == null)
			{
				Fuse.Diagnostics.InternalError( "Prepare without surface", this );
				return;
			}
			
			var b = obj as Brush;
			if (b != null)
				Surface.Prepare(b);
		}
		
		void IDrawObjectWatcherFeedback.Unprepare(object obj)
		{
			if (Surface == null)
			{
				Fuse.Diagnostics.InternalError( "Prepare without surface", this );
				return;
			}
			
			var b = obj as Brush;
			if (b != null)
				Surface.Unprepare(b);
		}
	}
	
	/*
		`Panel` and `VectorLayer` are both `ISurfaceDrawable` which share this code. We don't want
		`LayoutControl` to expose `ISurfaceDrawable` though, limiting it to only those derived classes.
		Thus they both have a small mixin component forwarding to these functions.
	*/
	public partial class LayoutControl
	{
		LayoutControlSurface _surface;
		internal Surface LayoutSurface 
		{
			get { return _surface != null ? _surface.Surface : null; }
		}
		
		internal void SurfaceRooted(bool require)
		{
			Surface surface;
			if (require)
				surface = SurfaceManager.FindOrCreate(this);
			else
				surface = SurfaceManager.Find(this);
				
			if (surface != null)
			{
				_surface = new LayoutControlSurface();
				_surface.LayoutControl = this;
				_surface.Surface = surface;
				_surface.Watcher = new DrawObjectWatcher();
				_surface.Watcher.OnRooted(_surface);
			}
		}
		
		internal void SurfaceUnrooted()
		{
			if (_surface != null)
			{
				if (_surface.BackgroundPath != null)
					_surface.Surface.DisposePath(_surface.BackgroundPath);
				_surface.Watcher.OnUnrooted();
					
				SurfaceManager.Release(this, _surface.Surface);
				_surface = null;
			}
		}
		
		internal void ISurfaceDrawableDraw(Surface surface)
		{
			if (_surface == null)
			{
				Fuse.Diagnostics.InternalError( "LayoutControl not properly rooted in Surface", this );
				return;
			}
			if (_surface.Surface != surface)
			{
				Fuse.Diagnostics.InternalError( "Mismatched surface", this );
			}

			_surface.Watcher.Reset();
			_surface.Watcher.Add(Background);
			_surface.Watcher.Sync();
			
			if (Background != null)
			{
				if (_surface.BackgroundPath == null || _surface.BackgroundPathSize != ActualSize)
				{
					var rs = ActualSize;
					var rect = new LineSegments();
					rect.MoveTo( float2(0) );
					rect.LineTo( float2(rs.X,0) );
					rect.LineTo( float2(rs.X,rs.Y));
					rect.LineTo( float2(0,rs.Y));
					rect.ClosePath();
					_surface.BackgroundPath = surface.CreatePath(rect.Segments);
					_surface.BackgroundPathSize = ActualSize;
				}
				
				surface.FillPath(_surface.BackgroundPath, Background);
			}
			
			var zOrder = GetCachedZOrder();
			for (int i = 0; i < zOrder.Length; i++)
			{
				var child = zOrder[i];
				var drawable = child as ISurfaceDrawable;
				if (drawable == null)
				{
					if (!_surface.WarnDraw)
					{
						Fuse.Diagnostics.UserWarning("Surface contains a non-drawable child", child);
						_surface.WarnDraw = true;
					}
					continue;
				}
				
				surface.PushTransform(child.LocalTransform);
				surface.DrawLocal(drawable);
				surface.PopTransform();
			}
		}
	}
}
