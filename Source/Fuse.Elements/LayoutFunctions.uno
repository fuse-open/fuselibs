using Uno;
using Uno.UX;
using Fuse.Reactive;

namespace Fuse.Elements
{
	/**
		These functions provide a layout property of an @Element.

		The returned values are the actual values, resulting after layout has been performed. If the element does not yet have a layout, or the layout has been lost, the values here will also be lost.

		[subclass Fuse.Elements.LayoutFunction]
		[subclass Fuse.Elements.XYBaseLayoutFunction]
	*/
	public abstract class LayoutFunction: Fuse.Reactive.Expression
	{
		Fuse.Reactive.Expression Element;
		internal LayoutFunction(Reactive.Expression element)
		{
			Element = element;
		}

		public override IDisposable Subscribe(IContext dc, IListener listener)
		{
			return new Subscription(this, dc, listener);
		}

		protected abstract object GetValue(PlacedArgs args);
		protected abstract object GetCurrentValue(Element elm);
		/* This allows an overriding of the functions, in particular `x` and `y` which can be vector accessors */
		protected virtual bool TryComputeAlternate(object value, out object result)
		{
			result = null;
			return false;
		}

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
					else
						_listener.OnLostData(_lf);
					return;
				}

				object value;
				if (_lf.TryComputeAlternate(elmObj, out value))
				{
					_listener.OnNewData(_lf, value);
					return;
				}

				Fuse.Diagnostics.UserError("Invalid value for LayoutFunction: " + elmObj, this);
				_listener.OnLostData(_lf);
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
	/**
		Returns the width of an @Element: `ActualSize.X`
	*/
	public sealed class WidthFunction: LayoutFunction
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
	/**
		Returns the height of an @Element: `ActualSize.Y`
	*/
	public sealed class HeightFunction: LayoutFunction
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

	/**
		These are overloaded functions that either provide a layout property or a vector component.

		[subclass Fuse.Elements.XYBaseLayoutFunction]
	*/
	public abstract class XYBaseLayoutFunction : LayoutFunction
	{
		internal XYBaseLayoutFunction(Reactive.Expression element): base(element) {}

		protected override bool TryComputeAlternate(object value, out object result)
		{
			result = null;
			var v = float4(0);
			int sz = 0;
			if (!Marshal.TryToZeroFloat4(value, out v, out sz))
				return false;

			return TryCompute(v, sz, out result);
		}

		protected abstract bool TryCompute(float4 v, int sz, out object value);
	}

	[UXFunction("x")]
	/**
		Returns one of:

		- The `ActualPosition.X` of an @Element. Refer to @LayoutFunction
		- The `X` value of a `float`, `float2`, `float3`, or `float4`
	*/
	public sealed class XFunction: XYBaseLayoutFunction
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

		protected override bool TryCompute(float4 v, int sz, out object value)
		{
			if (sz < 1)
			{
				value = null;
				return false;
			}
			value = v.X;
			return true;
		}
	}

	[UXFunction("y")]
	/**
		Returns one of:

		- The `ActualPosition.Y` of an @Element. Refer to @LayoutFunction
		- The `Y` value of a `float2`, `float3`, or `float4`
	*/
	public sealed class YFunction: XYBaseLayoutFunction
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

		protected override bool TryCompute(float4 v, int sz, out object value)
		{
			if (sz < 2)
			{
				value = null;
				return false;
			}
			value = v.Y;
			return true;
		}
	}
}