using Uno;
using Uno.UX;
using Fuse.Reactive;

namespace Fuse.Elements
{
	public abstract class LayoutFunction: UnaryOperator
	{
		protected LayoutFunction(Reactive.Expression element): base(element)
		{
		}

		public override IDisposable Subscribe(IContext dc, IListener listener)
		{
			return new LayoutSubscription(this, dc, listener);
		}

		protected abstract object GetValue(PlacedArgs args);
		protected abstract object GetCurrentValue(Element elm);

		class LayoutSubscription: Subscription
		{
			LayoutFunction _lf;

			public LayoutSubscription(LayoutFunction lf, IContext context, IListener listener): base(lf, listener)
			{
				_lf = lf;
				Init(context);
			}

			Element _element;
			protected override void OnNewOperand(object elmObj)
			{
				if (_element != null)
				{
					_element.Placed -= OnPlaced;
					_element = null;
				}

				_element = elmObj as Element;

				if (_element != null)
				{
					_element.Placed += OnPlaced;
					if (_element.HasMarginBox)
						PushNewData(_lf.GetCurrentValue(_element));
				}
			}

			void OnPlaced(object sender, PlacedArgs args)
			{
				PushNewData(_lf.GetValue(args));
			}

			public override void Dispose()
			{
				base.Dispose();
				_lf = null;
				if (_element != null) 
					_element.Placed -= OnPlaced;
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