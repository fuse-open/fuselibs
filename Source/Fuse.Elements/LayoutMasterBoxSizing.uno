using Uno;

namespace Fuse.Elements
{
	/**
		@see Element.LayoutMasterMode
	*/
	public enum LayoutMasterMode
	{
		/** The element gets a position to match it's world location to that of the master element; the element will have the same visual location and size and the master element. */
		ParentTransform,
		/** The element copies the master elements local size and position (relative to its own parent). */
		LocalLayout,
		/** The element copies the local size and position of the master element's parent. */
		ParentLayout,
	}

	internal sealed class LayoutMasterBoxSizing : BoxSizing
	{
		static public LayoutMasterBoxSizing Singleton = new LayoutMasterBoxSizing();

		public override BoxPlacement CalcBoxPlacement(Element element, float2 position,
			LayoutParams lp)
		{
			var master = GetLayoutMaster(element);
			if (master == null)
			{
				BoxPlacement bp;
				bp.MarginBox = element.ActualSize;
				bp.Position = element.ActualPosition;
				bp.Size = element.ActualSize;
				return bp;
			}

			return StandardBoxSizing.Singleton.CalcBoxPlacement(element, position, lp );
		}

		public override void RequestLayout(Element element)
		{
			var data = GetLayoutMasterData(element);
			data.ScheduleCheckLayout();
		}

		public override float2 CalcMarginSize(Element element, LayoutParams lp)
		{
			var master = GetLayoutMaster(element);
			if (master == null)
				return element.ActualSize;

			return StandardBoxSizing.Singleton.CalcMarginSize(element, lp);
		}

		override public float2 CalcArrangePaddingSize(Element element, LayoutParams lp)
		{
			return StandardBoxSizing.Singleton.CalcArrangePaddingSize(element, lp);
		}

		static readonly PropertyHandle _layoutMasterDataProperty = Fuse.Properties.CreateHandle();

		internal class LayoutMasterData
		{
			[WeakReference]
			public Element Element;

			public LayoutMasterMode Mode = LayoutMasterMode.ParentTransform;

			Element _master;
			public Element Master
			{
				get { return _master; }
				set
				{
					if (_master == value)
						return;

					if (_master != null)
						_master.Placed -= OnPlaced;

					_master = value;

					if (_master != null)
						_master.Placed += OnPlaced;

					if (Element.IsRootingCompleted)
						ScheduleCheckLayout();
				}
			}

			bool _pendingCheckLayout;
			internal void ScheduleCheckLayout()
			{
				//avoid wasted double processing
				if (!_pendingCheckLayout)
				{
					_pendingCheckLayout = true;
					UpdateManager.AddDeferredAction(CheckLayout);
				}
			}

			internal void CheckLayout()
			{
				_pendingCheckLayout = false;
				if (Element == null || _master == null || !_master.IsRootingCompleted || !Element.IsRootingCompleted)
					return;

				var pos = float2(0);
				var size = float2(0);

				if (Mode == LayoutMasterMode.LocalLayout)
				{
					pos = _master.ActualPosition;
					size = _master.ActualSize;
				}
				else if (Mode == LayoutMasterMode.ParentLayout)
				{
					var pe = _master.Parent as Element;
					if (pe != null)
					{
						pos = pe.ActualPosition;
						size = pe.ActualSize;
					}
				}
				else
				{
					var m = _master.Parent.GetTransformTo(Element.Parent);
					pos = Vector.Transform( _master.ActualPosition, m ).XY;
					var r = new Rect( float2(0), _master.ActualSize );
					size = Rect.Transform( r, m ).Size;
				}

				Element.ArrangeMarginBox( pos, LayoutParams.Create(size));
			}

			void OnPlaced(object s, object args)
			{
				UpdateManager.AddDeferredAction(CheckLayout);
			}
		}

		internal static LayoutMasterData GetLayoutMasterData(Element elm)
		{
			object v;
			if (elm.Properties.TryGet(_layoutMasterDataProperty, out v))
				return (LayoutMasterData)v;

			var sd = new LayoutMasterData();
			sd.Element = elm;
			elm.Properties.Set(_layoutMasterDataProperty, sd);
			return sd;
		}

		override public LayoutDependent IsContentRelativeSize(Element element)
		{
			return LayoutDependent.No;
		}

		//should only be used via `Element.LayoutMaster` for now
		//[UXAttachedPropertySetter("LayoutMasterBoxSizing.LayoutMaster")]
		internal static void SetLayoutMaster(Element elm, Element master)
		{
			GetLayoutMasterData(elm).Master = master;
		}

		//[UXAttachedPropertyGetter("LayoutMasterBoxSizing.LayoutMaster")]
		internal static Element GetLayoutMaster(Element elm)
		{
			return GetLayoutMasterData(elm).Master;
		}

		//[UXAttachedPropertyResetter("LayoutMasterBoxSizing.LayoutMaster")]
		internal static void ResetLayoutMaster(Element elm)
		{
			GetLayoutMasterData(elm).Master = null;
		}
	}
}
