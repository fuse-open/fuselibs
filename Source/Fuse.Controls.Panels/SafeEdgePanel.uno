using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Controls
{
	[Flags]
	/** 
		The sides of the @SafeEdgePanel that get system padding.
	*/
	public enum SafeEdgePanelEdges
	{
		None = 0,
		Left = 1 << 0,
		Top = 1 << 1,
		Right = 1 << 2,
		Bottom = 1 << 3,
		
		/* There is no way to combine flags in UX yet, thus we need all these variations.
			Naming order matches common float4 ordering of Left, Top, Right, Bottom. */
		LeftTop = Left | Top,
		LeftRight = Left | Right,
		LeftBottom = Left | Bottom,
		LeftTopRight = Left | Top | Right,
		LeftTopBottom = Left | Top | Bottom,
		LeftTopRightBottom = Left | Top | Right | Bottom,
		LeftRightBottom = Left | Right | Bottom,
		
		TopRight = Top | Right,
		TopBottom = Top | Bottom,
		TopRightBottom = Top | Right | Bottom,
		
		RightBottom = Right | Bottom,
	}
	
	/**
		`SafeEdgePanel` compensates for space taken up by the on-screen keyboard, status bar, and other OS-specific elements on the edges of the screen.  It should be used for any panel that touches any edge of the screen.
		
		See the article on [Safe Layout](articles:layout/safe-layout.md) for more details.
	*/
	public class SafeEdgePanel : Panel
	{
		WindowCaps _caps;
		
		SafeEdgePanelEdges _padEdges = SafeEdgePanelEdges.None;
		/**
			Apply safe padding to these edges of the panel.
		*/
		public SafeEdgePanelEdges PadEdges
		{
			get { return _padEdges; }
			set 
			{
				if (_padEdges == value)
					return;
				_padEdges = value;
				if (IsRootingCompleted)
					UpdatePadding();
			}
		}
		
		float4 _extraPadding = float4(0);
		/**
			Adds extra padding to the control, in addition to the safe padding applied by `PadEdges`.
			
			If you need extra padding use this property. You can't set `Padding` directly as that is implicitly controlled by this control.
		*/
		public float4 ExtraPadding
		{
			get { return _extraPadding; }
			set 
			{
				if (_extraPadding == value)
					return;
				_extraPadding = value;
				if (IsRootingCompleted)
					UpdatePadding();
			}
		}

		float4 _minEdgePadding = float4(0);
		/**
			A minimum value for the padding added by `PadEdges`.
			
			Some device orientations have large safe areas, such as landscape mode on the iPhone X. It may not be necessary to add extra padding in such layouts. Instead you can use `MinEdgePadding` to say how much visual padding is required as a minimum. If the safe area already covers that space no more padding is added. If the safe area isn't large enough then more padding is added.
			
			_This is not appropriate for all layouts, nor is it guaranteed to be pleasing on all devices. You should always test on several different models._
			
			Note that `ExtraPadding` is added after this minimum is applied.
		*/
		public float4 MinEdgePadding
		{
			get { return _minEdgePadding; }
			set 
			{
				if (_minEdgePadding == value)
					return;
				_minEdgePadding = value;
				if (IsRootingCompleted)
					UpdatePadding();
			}
		}

		/** Cannot be set directly on this control, use `ExtraPadding` instead. */
		public new float4 Padding
		{
			get { return base.Padding; }
			set { Fuse.Diagnostics.UserError( " `Padding` should not be set explicitly on a `SafeEdgePanel`, use `ExtraPadding` instead.", this ); }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			_caps = WindowCaps.AttachFrom(this);
			_caps.AddPropertyListener(this);
			UpdatePadding();
		}
		
		protected override void OnUnrooted()
		{
			_caps.RemovePropertyListener(this);
			_caps.Detach();
			_caps = null;
			base.OnUnrooted();
		}
		
		public override void OnPropertyChanged(PropertyObject sender, Selector name)
		{
			base.OnPropertyChanged(sender, name);
			if (sender == _caps && name == WindowCaps.NameSafeMargins)
				UpdatePadding();
		}
		
		void UpdatePadding()
		{
			var m = float4(0);
			if (!Marshal.TryToType<float4>(_caps[WindowCaps.NameSafeMargins], out m))
				m = float4(0);

			var edgePad = float4(
				PadEdges.HasFlag( SafeEdgePanelEdges.Left ) ? m[0] : 0,
				PadEdges.HasFlag( SafeEdgePanelEdges.Top ) ? m[1] : 0,
				PadEdges.HasFlag( SafeEdgePanelEdges.Right ) ? m[2] : 0,
				PadEdges.HasFlag( SafeEdgePanelEdges.Bottom ) ? m[3] : 0 );
			base.Padding = ExtraPadding + Math.Max( MinEdgePadding, edgePad );
		}
	}
}
