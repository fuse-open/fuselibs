using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;
using Uno.Runtime.Implementation;
using Uno.Runtime.Implementation.Internal;

namespace Fuse.Elements
{
	/**
		For any placement change the following happens:

		- child layout is performed
		- Preplacement dispatched
		- actual local placement modified
		- layout change event deferred
	*/
	public class PreplacementArgs : EventArgs
	{
		//was this element placed before since rooting
		public bool HasPrev { get; private set; }

		internal PreplacementArgs(bool hasPrev)
		{
			HasPrev = hasPrev;
		}
	}

	public delegate void PreplacementHandler(object sender, PreplacementArgs args);

	public abstract partial class Element
	{
		protected override float2 AbsoluteViewportOrigin
		{
			get
			{
				var p = ActualPosition;
				p += base.AbsoluteViewportOrigin;
				return p;
			}
		}

		internal float2 _actualPosition;
		float2 _actualPositionCache;
		bool _haveActualPositionCache = false;
		/**
			The position of the element, the position of its top-left corner to the top-left corner in the parent.

			Only available after layout of the element is complete.
		*/
		public float2 ActualPosition
		{
			get
			{
				if (_haveActualPositionCache)
					return _actualPositionCache;

				if (!SnapToPixels)
					return _actualPosition;

				var parentP = float2(0);
				if (Parent != null)
					parentP = Parent.AbsoluteViewportOrigin;

				var p = parentP + _actualPosition;
				p = Snap(p);
				p = p - parentP;

				_actualPositionCache = p;
				_haveActualPositionCache = true;
				return p;
			}
		}

		internal float2 _actualSize, _intendedSize;


		/**
			The size of the element.

			This is the resulting size after layout and may not match the requested `Width`, `Height`, or other size properties. Those are all interpreted to produce this resulting size.

			Only available after layout of the element is complete.
		*/
		public float2 ActualSize
		{
			get { return _actualSize; }
		}

		internal float2 IntendedSize
		{
			get { return _intendedSize; }
		}

		internal float2 IntendedPosition
		{
			get { return ActualPosition; } //there is no temporary position yet
		}

		float3 IActualPlacement.ActualSize { get { return float3(ActualSize, 0); } }
		float3 IActualPlacement.ActualPosition { get { return float3(ActualPosition, 0); } }
		//IActualPlacement.Placed implemented by normal `Placed`

		static int _getMarginSizeCalls, _getContentSizeCalls;

		/*
			Percent: Is a factor of the remaining size of the fill space after global adjustments and removing
			local margins. It then specifies the size of the padding box.
		*/

		float UnitSize( Size s, float fill, bool secondary, out bool known )
		{
			known = true;

			var u = s.DetermineUnit();

			if (u == Unit.Points)
				return s.Value;

			if (u == Unit.Pixels)
				return s.Value / AbsoluteZoom;

			//Percent
			if (secondary)
				return s.Value * fill / 100f;

			known = false;
			return 0;
		}


		struct GMSCacheItem
		{
			public LayoutParams layoutParams;
			public float2 result;
		}
		int _gmsCount = 0, _gmsAt = 0;
		//2 since we quite often have GetMarginSize called by a parent sizing request and then also
		//for the local arrange. It'd be nice to get rid of those duplicate calls
		const int _gmsMax = 2;
		GMSCacheItem[] _gmsCache = new GMSCacheItem[_gmsMax];

		void GMSReset()
		{
			_gmsCount = 0;
			_gmsAt = 0;
		}

		/**
			The sizing system used to calculate the layout of an element.

			@see Element.BoxSizing
		*/
		public enum BoxSizingMode
		{
			Standard,
			NoImplicitMax,
			Limit,
			LayoutMaster,
			FillAspect,
		}

		BoxSizing _boxSizing = StandardBoxSizing.Singleton;
		BoxSizingMode _boxSizingMode = BoxSizingMode.Standard;
		/**
			The manner in which the size and position of the element is calculated.

			@remarks Docs/BoxSizing.md
		*/
		public BoxSizingMode BoxSizing
		{
			get { return _boxSizingMode; }
			set
			{
				if (value == _boxSizingMode)
					return;

				_boxSizingMode = value;
				switch (_boxSizingMode)
				{
					case BoxSizingMode.Standard: _boxSizing = StandardBoxSizing.Singleton; break;
					case BoxSizingMode.NoImplicitMax: _boxSizing = NoImplicitMaxBoxSizing.Singleton; break;
					case BoxSizingMode.Limit: _boxSizing = LimitBoxSizing.Singleton; break;
					case BoxSizingMode.LayoutMaster: _boxSizing = LayoutMasterBoxSizing.Singleton; break;
					case BoxSizingMode.FillAspect: _boxSizing = FillAspectBoxSizing.Singleton; break;
				}

				InvalidateLayout();
			}
		}

		internal BoxSizing BoxSizingObject
		{
			get { return _boxSizing; }
		}

		internal void RequestLayout()
		{
			_boxSizing.RequestLayout(this);
		}

		//TODO: This should be sealed, looks like an odd compiler error in a particular test breaks it
		public /*sealed*/ override float2 GetMarginSize(LayoutParams lp)
		{
			for (int i=0; i < _gmsCount; ++i )
			{
				var g = _gmsCache[i];
				if (g.layoutParams.IsCompatible(lp))
					return g.result;
			}
			var sz = _boxSizing.CalcMarginSize(this, lp);

			var n = (_gmsAt++) % _gmsMax;
			_gmsCount = Math.Min( _gmsMax, _gmsCount+1);
			_gmsCache[n] = new GMSCacheItem
			{
				layoutParams = lp.Clone(),
				result = sz,
			};

			return sz;
		}

		internal float2 InternGetContentSize(LayoutParams lp)
		{
			return GetContentSize(lp);
		}

		protected virtual float2 GetContentSize(LayoutParams lp)
		{
			return float2(0);
		}

		internal protected float2 GetArrangePaddingSize(LayoutParams lp)
		{
			return _boxSizing.CalcArrangePaddingSize(this, lp);
		}

		float2 _actualAnchor;
		/**
			The anchor of element.

			Only available after layout of the element is complete.

			@see Element.Anchor
		*/
		public float2 ActualAnchor
		{
			get { return _actualAnchor; }
			internal set { _actualAnchor = value; }
		}

		static bool _invalidValuesWarn = false;
		protected override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
		{
			var bp = _boxSizing.CalcBoxPlacement(this, position, lp);
			if (bp.SanityConstrain())
			{
				//just once since the user can't really do anything more than report the error
				if (!_invalidValuesWarn)
					Fuse.Diagnostics.InternalError( "Invalid values in ArrangeMarginBox", this );
				_invalidValuesWarn = true;
			}

			if (!(lp.Temporary && ignoreTempArrange))
			{
				if (Visibility != Visibility.Collapsed)
				{
					var nlp = lp.CloneAndDerive();
					nlp.SetSize(bp.Size);
					ArrangePaddingBox(nlp);
					PerformPlacement(bp.Position, bp.Size, lp.Temporary);
				}
			}
			return bp.MarginBox;
		}

		/** Raised when the element receives a new position and size by the layout engine.

			Event handlers are called with an instance of [PlacedArgs](api:fuse/placedargs).

			All coordinates are in the parent node's local space, in points.

			> **Note:** Due to the asynchronous nature of JavaScript and the way it communicates with UX,
			> there is no guarantee of exactly _when_ an event handler will fire. For this reason,
			> **we strongly discourage using `Placed` or JavaScript in general for controlling layout**,
			> as doing so can lead to flickering and other artifacts.

			## Example

				<JavaScript>
					function panelPlaced(args) {
						console.dir("New position:", [args.x, args.y]);
						console.dir("New size:", [args.width, args.height]);
					}

					module.exports = { panelPlaced: panelPlaced };
				</JavaScript>

				<Panel Placed="{panelPlaced}"/>
		*/
		public event PlacedHandler Placed;

		/** @advanced
		*/
		public event PreplacementHandler Preplacement;

		[WeakReference]
		Node _placedBefore;

		float2 _ppPrevSize;
		float2 _ppPrevPosition;

		void OnPreplacement()
		{
			if (Preplacement != null)
				Preplacement(this, new PreplacementArgs(_placedBefore != null));
		}

		internal override void OnPreserveRootFrame()
		{
			base.OnPreserveRootFrame();
			OnPreplacement();
		}

		internal bool ignoreTempArrange;

		internal override bool CanAdjustMarginBox { get { return true; } }
		internal override void OnAdjustMarginBoxPosition( float2 position )
		{
			//optimization to avoid new ArrangeMarginBox. This assumes a linear 1:1 relationship on the position
			PerformPlacement( _actualPosition + (position - MarginBoxPosition),
				_actualSize, false);
		}

		/**
			This is the only function which is allowed to modify the actual size/position
			variables! This is expected to be called at most once per frame.
		*/
		internal void PerformPlacement(float2 position, float2 size, bool temp)
		{
			var s = Math.Max(size, float2(0));

			_ppPrevSize = _intendedSize;
			_ppPrevPosition = ActualPosition;

			//must check both current and intended in case something is modifying the temporary size
			//when a true placement happens
			var newSize = _ppPrevSize != s || _actualSize != s;
			var newPosition = _ppPrevPosition.X != position.X || _ppPrevPosition.Y != position.Y;
			bool newParent = _placedBefore != Parent;

			if (newParent || newPosition || newSize)
			{
				if (!temp && !_pendingDispatchPlacement)
				{
					OnPreplacement(); //must happen before any actual changes take place
					if (TreeRenderer != null)
					{
						UpdateManager.AddDeferredAction(NotifyTreeRendererPlaced, LayoutPriority.Placement);
					}
					if (Placed != null)
					{
						UpdateManager.AddDeferredAction(DispatchPlacement, LayoutPriority.Placement);
						_pendingDispatchPlacement = true;
					}
					else
					{
						_placedBefore = Parent;
					}
				}
			}

			if (newSize)
			{
				_actualSize = s;
				if (!temp)
					_intendedSize = s;
			}

			if (newSize || newParent)
			{
				InvalidateRenderBounds();
				InvalidateHitTestBounds();
			}

			if (newPosition)
			{
				_actualPosition = position;
				_haveActualPositionCache = false;
				InvalidateVisualComposition();
			}

			if (newSize || newParent || newPosition)
				InvalidateLocalTransform();
		}

		bool _pendingDispatchPlacement;
		void DispatchPlacement()
		{
			_pendingDispatchPlacement = false;

			if (Placed != null)
			{
				var args = new PlacedArgs(_placedBefore != null, _ppPrevPosition, ActualPosition,
					_ppPrevSize, ActualSize);
				Placed(this, args);
			}
			_placedBefore = Parent;
		}

		void NotifyTreeRendererPlaced()
		{
			var t = TreeRenderer;
			if (t != null)
				t.Placed(this);
		}

		internal void InternArrangePaddingBox(LayoutParams lp) { ArrangePaddingBox(lp); }

		/**
			The provided LayoutParams is guaranteed to have a defined size that should be used
			to layout the padding box.

			NOTE: ActualSize and ActualPosition will not be updated at this time.
		*/
		protected virtual void ArrangePaddingBox(LayoutParams lp)
		{
		}

		/**
			@return true if this element has a proper layout relative to the given target node.
		*/
		internal bool HasLayoutIn(Visual target)
		{
			var e = this;
			while( e != target )
			{
				e = e.Parent as Element;
				if (e == null)
					return false;
			}

			return true;
		}

		/**
			Obtains the layout position of an element in a target.
		*/
		internal float2 GetLayoutPositionIn(Visual target)
		{
			var e = this;
			var p = float2(0);
			do
			{
				p += e.ActualPosition;
				e = e.Parent as Element;
			}
			while (e != target && e != null);

			return p;
		}

	}
}
