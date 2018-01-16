using Uno;
using Uno.UX;

using Fuse.Common;
using Fuse.Nodes;
using Fuse.Triggers;

namespace Fuse.Controls
{
	public partial class Panel
	{
		bool _freezeAwaitPrepared;
		framebuffer _frozenBuffer;
		bool HasFreezePrepared { get { return _frozenBuffer != null; } }
		
		internal bool TestHasFreezePrepared { get { return HasFreezePrepared; } }
		
		bool _isFrozen;
		/**
			When `true` the panel is in a frozen state. This means:
				- layout of the children is blocked
				- child invalidation does not invalidate this panel
				- the visual drawing is captured once and used for all future drawing
				
			`IsFrozen` allows improving performance in some use-cases, such as Navigation, where the children may not be completely stable. This can result from such things as data bindings resolving, deferred items resolving, and images loading. Note that it will also block all intentional animation as well until unfrozen.
			
			Warning: Trigger timing is not blocked at the moment, and animations will jump over the lost time when unfrozen again.
		*/
		public bool IsFrozen
		{
			get { return _isFrozen; }
			set
			{
				if (_isFrozen == value)
					return;
					
				_isFrozen = value;
				if (!IsRootingCompleted)
					return;
					
				CleanupBuffer();
				if (_isFrozen && !HasFreezePrepared)
					SetupListener();
				else
					CleanupListener();
					
				if (!_isFrozen)
				{
					InvalidateLayout();
					InvalidateVisual();
				}
			}
		}
		
		void CleanupBuffer()
		{
			if (_frozenBuffer != null)
			{
				FramebufferPool.Release(_frozenBuffer);
				_frozenBuffer = null;
			}
		}
		
		void CleanupListener(bool nextFrame = false)
		{
			if (_freezeAwaitPrepared)
			{
				Internal.DrawManager.Prepared -= OnPrepared;
				//it's vital not to send messages in the draw frame
				if (nextFrame)
					UpdateManager.PerformNextFrame(EndBusy);
				else
					EndBusy();
				_freezeAwaitPrepared = false;
			}
		}
		
		void EndBusy()
		{
			BusyTask.SetBusy(this, ref _freezeBusyTask, BusyTaskActivity.None);
		}
		
		BusyTask _freezeBusyTask;
		void SetupListener()
		{
			if (LayoutSurface != null)
			{
				Fuse.Diagnostics.UserError( "Panel.IsFrozen cannot be used when a Panel is in a Surface", this );
				return;
			}
				
			if (!_freezeAwaitPrepared)
			{
				Internal.DrawManager.Prepared += OnPrepared;
				BusyTask.SetBusy(this, ref _freezeBusyTask, BusyTaskActivity.Preparing);
				_freezeAwaitPrepared = true;
			}
		}
		
		BusyTaskActivity _deferFreeze = BusyTaskActivity.None;
		/**
			Defers the freezing of the panel until the children are no longer busy.
			
			When `None` (the default), the freezing will happen the same frame `IsFrozen` is set to `true`. Otherwise the panel will wait for all children to clear the busy status of this type before doing the freezing.
		*/
		public BusyTaskActivity DeferFreeze
		{
			get { return _deferFreeze; }
			set { _deferFreeze = value; }
		}
		
		void FreezeRooted()
		{	
			if (IsFrozen)
				SetupListener();
		}
		
		void FreezeUnrooted()
		{
			CleanupBuffer();
			CleanupListener();
		}
		
		float2 _frozenActualSize;
		VisualBounds _frozenRenderBounds;
		void OnPrepared(DrawContext dc)
		{
			//don't freeze if still waiting on other activity 
			if (DeferFreeze != BusyTaskActivity.None)
			{
				var b = BusyTask.GetBusyActivity(this, BusyTaskMatch.OnlyDescendents);
				if ( (b & DeferFreeze) != BusyTaskActivity.None )
					return;
			}
			
			CleanupListener(true);
			_frozenRenderBounds = base.LocalRenderBounds;
			if (!_frozenRenderBounds.IsFlat || _frozenRenderBounds.IsInfinite)
			{
				Fuse.Diagnostics.InternalError( "unable to freeze non-flat or infinite element", this);
				return;
			}
			
			_frozenBuffer = CaptureRegion(dc, _frozenRenderBounds.FlatRect, float2(0));
			if (_frozenBuffer == null)
			{
				Fuse.Diagnostics.InternalError( "unable to freeze element", this);
				return;
			}
			
			_frozenActualSize = ActualSize;
		}
		
		protected sealed override float2 GetContentSize(LayoutParams lp)
		{
			if (HasFreezePrepared)
				return _frozenActualSize;
			return base.GetContentSize(lp);
		}
		
		protected sealed override void ArrangePaddingBox(LayoutParams lp)
		{
			if (HasFreezePrepared)
				return;
			base.ArrangePaddingBox(lp);
		}
		
		public sealed override VisualBounds LocalRenderBounds
		{
			get
			{
				if (HasFreezePrepared)
					return _frozenRenderBounds.Scale(float3(Scale,1));
				return base.LocalRenderBounds;
			}
		}
		
		protected sealed override bool FastTrackDrawWithOpacity(DrawContext dc)
		{
			if (IsFrozen && HasFreezePrepared)
			{
				var rect = Rect.Scale(_frozenRenderBounds.FlatRect, Scale);
				Blitter.Singleton.Blit(
					_frozenBuffer.ColorBuffer,
					rect,
					dc.GetLocalToClipTransform(this),
					Opacity,
					true);

					if defined(FUSELIBS_DEBUG_DRAW_RECTS)
						DrawRectVisualizer.Capture(rect.Minimum, rect.Size, WorldTransform, dc);

				return true;
			}

			return base.FastTrackDrawWithOpacity(dc);
		}

		//freezing doesn't block changing the size of this element. To accomodate new
		//sizes we stretch the frozen content into the new size
		float2 Scale { get { return ActualSize / _frozenActualSize; } }
		
		public sealed override void Draw(DrawContext dc)
		{
			if (!IsFrozen || !HasFreezePrepared)
			{
				base.Draw(dc);
				return;
			}

			var rect = Rect.Scale(_frozenRenderBounds.FlatRect, Scale);
			Blitter.Singleton.Blit(
				_frozenBuffer.ColorBuffer,
				rect,
				dc.GetLocalToClipTransform(this),
				Opacity,
				true);

				if defined(FUSELIBS_DEBUG_DRAW_RECTS)
					DrawRectVisualizer.Capture(rect.Minimum, rect.Size, WorldTransform, dc);
		}
		
		internal override bool IsLayoutRoot
		{
			get { return HasFreezePrepared; }
		}
	}
}
