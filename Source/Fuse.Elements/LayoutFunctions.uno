using Uno;
using Uno.UX;
using Fuse.Reactive;

namespace Fuse.Elements
{
	public abstract class LayoutFunction: Fuse.Reactive.Expression
	{
		Fuse.Reactive.Expression Element;
		protected LayoutFunction(Reactive.Expression element)
		{
			Element = element;
		}

		public override IDisposable Subscribe(IContext dc, IListener listener)
		{
			return new Subscription(this, dc, listener);
		}

		protected abstract object GetValue(PlacedArgs args);
		protected abstract object GetCurrentValue(Element elm);

		class Subscription: InnerListener
		{
			LayoutFunction _lf;
			IListener _listener;
			IDisposable _sub;

			public Subscription(LayoutFunction lf, IContext context, IListener listener)
			{
				_lf = lf;
				_listener = listener;
				_sub = _lf.Element.Subscribe(context, this);
			}

			Element _element;
			protected override void OnNewData(IExpression source, object elmObj)
			{
				UnsubscribeElement();

				_element = elmObj as Element;

				if (_element != null)
				{
					_element.Placed += OnPlaced;
					_element.LostMarginBox += OnLostMarginBox;
					if (_element.HasMarginBox)
						_listener.OnNewData(_lf, _lf.GetCurrentValue(_element));
				}
			}
			
			protected override void OnLostData(IExpression source)
			{
				UnsubscribeElement();
				_listener.OnLostData(_lf);
			}

			void OnPlaced(object sender, PlacedArgs args)
			{
				_listener.OnNewData(_lf, _lf.GetValue(args));
			}
			
			void OnLostMarginBox(object sender, LostMarginBoxArgs args)
			{
				_listener.OnLostData(_lf);
			}

			void UnsubscribeElement()
			{
				if (_element != null) 
				{
					_element.Placed -= OnPlaced;
					_element.LostMarginBox -= OnLostMarginBox;
					_element = null;
				}
			}
				
			public override void Dispose()
			{
				base.Dispose();
				_lf = null;
				UnsubscribeElement();
				if (_sub != null)
				{
					_sub.Dispose();
					_sub = null;
				}
			}
		}
	}

	[UXFunction("width")]
	public class WidthFunction: LayoutFunction
	{
		[UXConstructor]
		public WidthFunction([UXParameter("Element")] Reactive.Expression element): base(element) {}

		protected override object GetValue(PlacedArgs args)
		{
			return args.NewSize.X;
		}
		
		protected override object GetCurrentValue(Element elm)
		{
			return elm.ActualSize.X;
		}
	}

	[UXFunction("height")]
	public class HeightFunction: LayoutFunction
	{
		[UXConstructor]
		public HeightFunction([UXParameter("Element")] Reactive.Expression element): base(element) {}

		protected override object GetValue(PlacedArgs args)
		{
			return args.NewSize.Y;
		}
		
		protected override object GetCurrentValue(Element elm)
		{
			return elm.ActualSize.Y;
		}
	}

	[UXFunction("x")]
	public class XFunction: LayoutFunction
	{
		[UXConstructor]
		public XFunction([UXParameter("Element")] Reactive.Expression element): base(element) {}

		protected override object GetValue(PlacedArgs args)
		{
			return args.NewPosition.X;
		}
		
		protected override object GetCurrentValue(Element elm)
		{
			return elm.ActualPosition.X;
		}
	}

	[UXFunction("y")]
	public class YFunction: LayoutFunction
	{
		[UXConstructor]
		public YFunction([UXParameter("Element")] Reactive.Expression element): base(element) {}

		protected override object GetValue(PlacedArgs args)
		{
			return args.NewPosition.Y;
		}
		
		protected override object GetCurrentValue(Element elm)
		{
			return elm.ActualPosition.Y;
		}
	}
}