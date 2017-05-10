using Uno;
using Uno.UX;

namespace Fuse.Animations
{
	/** Represents an easing function, and contains common easing functions.

		Easing functions map an otherwise linear motion into a different curve type,
		typically desired to make animations look more natural or expressive.
		Easing is available as a property on most animators, such as @Change, @Move, 
		@Rotate and @Scale.
	*/
	public abstract class Easing
	{
		/** Computes the mapped easing value. */
		public abstract double Map(double p);

		[UXGlobalResource] public static readonly Easing Linear = new LinearImpl();

		[UXGlobalResource] public static readonly Easing QuadraticIn = new QuadraticInImpl();
		[UXGlobalResource] public static readonly Easing QuadraticOut = new QuadraticOutImpl();
		[UXGlobalResource] public static readonly Easing QuadraticInOut = new QuadraticInOutImpl();

		[UXGlobalResource] public static readonly Easing CubicIn = new CubicInImpl();
		[UXGlobalResource] public static readonly Easing CubicOut = new CubicOutImpl();
		[UXGlobalResource] public static readonly Easing CubicInOut = new CubicInOutImpl();

		[UXGlobalResource] public static readonly Easing QuarticIn = new QuarticInImpl();
		[UXGlobalResource] public static readonly Easing QuarticOut = new QuarticOutImpl();
		[UXGlobalResource] public static readonly Easing QuarticInOut = new QuarticInOutImpl();

		[UXGlobalResource] public static readonly Easing QuinticIn = new QuinticInImpl();
		[UXGlobalResource] public static readonly Easing QuinticOut = new QuinticOutImpl();
		[UXGlobalResource] public static readonly Easing QuinticInOut = new QuinticInOutImpl();

		[UXGlobalResource] public static readonly Easing SinusoidalIn = new SinusoidalInImpl();
		[UXGlobalResource] public static readonly Easing SinusoidalOut = new SinusoidalOutImpl();
		[UXGlobalResource] public static readonly Easing SinusoidalInOut = new SinusoidalInOutImpl();

		[UXGlobalResource] public static readonly Easing ExponentialIn = new ExponentialInImpl();
		[UXGlobalResource] public static readonly Easing ExponentialOut = new ExponentialOutImpl();
		[UXGlobalResource] public static readonly Easing ExponentialInOut = new ExponentialInOutImpl();

		[UXGlobalResource] public static readonly Easing CircularIn = new CircularInImpl();
		[UXGlobalResource] public static readonly Easing CircularOut = new CircularOutImpl();
		[UXGlobalResource] public static readonly Easing CircularInOut = new CircularInOutImpl();

		[UXGlobalResource] public static readonly Easing ElasticIn = new ElasticInImpl();
		[UXGlobalResource] public static readonly Easing ElasticOut = new ElasticOutImpl();
		[UXGlobalResource] public static readonly Easing ElasticInOut = new ElasticInOutImpl();

		[UXGlobalResource] public static readonly Easing BackIn = new BackInImpl();
		[UXGlobalResource] public static readonly Easing BackOut = new BackOutImpl();
		[UXGlobalResource] public static readonly Easing BackInOut = new BackInOutImpl();

		[UXGlobalResource] public static readonly Easing BounceIn = new BounceInImpl();
		[UXGlobalResource] public static readonly Easing BounceOut = new BounceOutImpl();
		[UXGlobalResource] public static readonly Easing BounceInOut = new BounceInOutImpl();
	
		internal class LinearImpl: Easing
		{
			public override double Map(double k)
			{
				return k;
			}
		}

		internal class QuadraticInImpl: Easing
		{
			public override double Map(double k)
			{
				return k * k;
			}
		}

		internal class QuadraticOutImpl: Easing
		{
			public override double Map(double k)
			{
				return k * (2 - k);
			}
		}

		internal class QuadraticInOutImpl: Easing
		{
			public override double Map(double k)
			{
				k *= 2;
				if (k < 1.0f)
				{
					return 0.5 * k * k;
				}

				k -= 1;
				return -0.5 * (k * (k - 2) - 1);
			}
		}

		internal class CubicInImpl: Easing
		{
			public override double Map(double k)
			{
				return k * k * k;
			}
		}

		internal class CubicOutImpl: Easing
		{
			public override double Map(double k)
			{
				k -= 1;
				return k * k * k + 1;
			}
		}

		internal class CubicInOutImpl: Easing
		{
			public override double Map(double k)
			{
				k *= 2;
				if (k < 1)
					return 0.5 * k * k * k;

				k -= 2;
				return 0.5 * (k * k * k + 2);
			}
		}

		internal class QuarticInImpl: Easing
		{
			public override double Map(double k)
			{
				 return k * k * k * k;
			}
		}

		internal class QuarticOutImpl: Easing
		{
			public override double Map(double k)
			{
				k -= 1;
				return 1 - (k * k * k * k);
			}
		}

		internal class QuarticInOutImpl: Easing
		{
			public override double Map(double k)
			{
				k *= 2;
				if (k < 1)
					return 0.5 * k * k * k * k;
				k -= 2;
				return - 0.5 * (k * k * k * k - 2);
			}
		}

		internal class QuinticInImpl: Easing
		{
			public override double Map(double k)
			{
				return k * k * k * k * k;
			}
		}

		internal class QuinticOutImpl: Easing
		{
			public override double Map(double k)
			{
				k -= 1;
				return k * k * k * k * k + 1;
			}
		}

		internal class QuinticInOutImpl: Easing
		{
			public override double Map(double k)
			{
				k *= 2;
				if (k < 1)
					return 0.5 * k * k * k * k * k;

				k -= 2;
				return 0.5 * (k * k * k * k * k + 2);
			}
		}

		internal class SinusoidalInImpl: Easing
		{
			public override double Map(double k)
			{
				return 1 - Math.Cos(k * Math.PI / 2);
			}
		}

		internal class SinusoidalOutImpl: Easing
		{
			public override double Map(double k)
			{
				return Math.Sin(k * Math.PI / 2);
			}
		}

		internal class SinusoidalInOutImpl: Easing
		{
			public override double Map(double k)
			{
				return 0.5 * (1 - Math.Cos(Math.PI * k));
			}
		}

		internal class ExponentialInImpl: Easing
		{
			public override double Map(double k)
			{
				return k == 0 ? 0.0 : Math.Pow(1024, k - 1);
			}
		}

		internal class ExponentialOutImpl: Easing
		{
			public override double Map(double k)
			{
				return k == 1 ? 1.0 : 1 - Math.Pow(2, - 10 * k);
			}
		}

		internal class ExponentialInOutImpl: Easing
		{
			public override double Map(double k)
			{
				if (k == 0)
					return 0;

				if (k == 1)
					return 1;

				k *= 2;
				if (k < 1)
					return 0.5 * Math.Pow(1024, k - 1);

				return 0.5 * (-Math.Pow(2, - 10 * (k - 1)) + 2);
			}
		}

		internal class CircularInImpl: Easing
		{
			public override double Map(double k)
			{
				return 1 - Math.Sqrt(1 - k * k);
			}
		}

		internal class CircularOutImpl: Easing
		{
			public override double Map(double k)
			{
				k = k - 1.0f;
				return Math.Sqrt(1 - (k * k));
			}
		}

		internal class CircularInOutImpl: Easing
		{
			public override double Map(double k)
			{
				k *= 2;
				if (k < 1)
					return - 0.5 * (Math.Sqrt(1 - k * k) - 1);
				k -= 2;
				return 0.5 * (Math.Sqrt(1 - k * k) + 1);
			}
		}

		internal class ElasticInImpl: Easing
		{
			public override double Map(double k)
			{
				if (k == 0)
					return 0;

				if (k == 1)
					return 1;
				k -= 1;
				return -Math.Pow(2, 10 * k) * Math.Sin((k - 0.1f) * (2 * Math.PIf) * 2.5f);
			}
		}

		internal class ElasticOutImpl: Easing
		{
			public override double Map(double k)
			{
				if (k == 0)
					return 0;

				if (k == 1)
					return 1;

				return Math.Pow(2, - 10 * k) * Math.Sin((k - 0.1f) * (2 * Math.PIf) * 2.5f) + 1;
			}
		}

		internal class ElasticInOutImpl: Easing
		{
			public override double Map(double k)
			{
				if (k == 0)
					return 0;

				if (k == 1)
					return 1;

				k = k * 2 - 1;
				if (k < 0)
					return - 0.5 * Math.Pow(2, 10 * k) * Math.Sin((k - 0.1f) * (2 * Math.PIf) * 2.5f);
				return Math.Pow(2, -10 * k) * Math.Sin((k - 0.1f) * (2 * Math.PIf) * 2.5f) * 0.5 + 1;
			}
		}

		internal class BackInImpl: Easing
		{
			public override double Map(double k)
			{
				var s = 1.70158f;
				return k * k * ((s + 1) * k - s);
			}
		}

		internal class BackOutImpl: Easing
		{
			public override double Map(double k)
			{
				var s = 1.70158f;
				k = k - 1.0f;
				return k * k * ((s + 1) * k + s) + 1;
			}
		}

		internal class BackInOutImpl: Easing
		{
			public override double Map(double k)
			{
				var s = 1.70158f * 1.525f;

				k *= 2;
				if (k < 1)
					return 0.5 * (k * k * ((s + 1) * k - s));

				k -= 2;
				return 0.5 * (k * k * ((s + 1) * k + s) + 2);
			}
		}

		internal class BounceInImpl: Easing
		{
			public override double Map(double k)
			{
				return 1 - Easing.BounceOut.Map(1 - k);
			}
		}

		internal class BounceOutImpl: Easing
		{
			public override double Map(double k)
			{
				if (k < (1 / 2.75f))
				{
					return 7.5625f * k * k;
				}
				else if (k < (2 / 2.75f))
				{
					k -= 1.5f / 2.75f;
					return 7.5625f * k * k + 0.75f;
				}
				else if (k < (2.5f / 2.75f))
				{
					k -= 2.25f / 2.75f;
					return 7.562f * k * k + 0.9375f;
				}
				else
				{
					k -= 2.625f / 2.75f;
					return 7.5625f * k * k + 0.984375f;
				}
			}
		}

		internal class BounceInOutImpl: Easing
		{
			public override double Map(double k)
			{
				if (k < 0.5)
					return Easing.BounceIn.Map(k * 2) * 0.5;
				return Easing.BounceOut.Map(k * 2 - 1) * 0.5 + 0.5;
			}
		}
	}

	/** Represents a cubic bezier easing curve.

		A cubic bezier curve is defined by four control points. In an Easing curve, the first control point is fixed at (0,0),
		while the last control point is fixed at (1,1) the two remaining control points are configurable.

		## Example

			<Rectangle Width="100" Height="100" Color="#18f" CornerRadius="10">
				<WhilePressed>
					<Move X="100" Duration="0.3">
						<CubicBezierEasing ControlPoints="0.4, 0.0, 1.0, 1.0" />
					</Move>
				</WhilePressed>
			</Rectangle>

		The above `CubicBezierEasing` is equivalent to:

			// In iOS
			[CAMediaTimingFunction alloc] initWithControlPoints:0.4f:0.0f:1.0f:1.0f]

			// In Android
			FastOutLinearInInterpolator

			// In CSS
			cubic-bezier(0.4, 0.0, 1, 1);

			// In After Effects
			Outgoing Velocity: 40%
			Incoming Velocity: 0%

		## Different `Easing` and `EasingBack`

		You can use `ux:Binding` to specify two different easing curves for `Easing` and `EasingBack`:

			<Move X="100" Duration="0.3">
				<CubicBezierEasing ux:Binding="Easing" ControlPoints="0.4, 0.0, 1.0, 1.0" />
				<CubicBezierEasing ux:Binding="EasingBack" ControlPoints="0.3, 0.0, 0.3, 1.0" />
			</Move>

		## Creating new global easing functions

		You can use `ux:Global to define a new global easing curve:

			<CubicBezierEasing ux:Global="MyStandardEasing" ControlPoints="0.4, 0.0, 1.0, 1.0" />

		And then:

			<Move X="100" Duration="0.3" Easing="MyStandardEasing" />

	*/
	public class CubicBezierEasing: Easing
	{
		const double C0X = 0.0;
		const double C0Y = 0.0;
		const double C3X = 1.0;
		const double C3Y = 1.0;

		public double C1X { get; set; }
		public double C1Y { get; set; }
		public double C2X { get; set; }
		public double C2Y { get; set; }

		public float4 ControlPoints
		{
			get { return float4((float)C1X, (float)C1Y, (float)C2X, (float)C2Y); }
			set { C1X = value.X; C1Y = value.Y; C2X = value.Z; C2Y = value.W; }
		}

		public override double Map(double p)
		{
			var a =   C3X - 3*C2X + 3*C1X - C0X;
			var b = 3*C2X - 6*C1X + 3*C0X;
			var c = 3*C1X - 3*C0X;
			var d =   C0X;

			var e =   C3Y - 3*C2Y + 3*C1Y - C0Y;
			var f = 3*C2Y - 6*C1Y + 3*C0Y;
			var g = 3*C1Y - 3*C0Y;
			var h =   C0Y;

			var t = p;
			for (int i = 0; i < 5; i++)
			{
				var x = a*(t*t*t) + b*(t*t) + c*t + d; 
				var q = (3.0*a*t*t + 2.0*b*t + c);
				if (Math.Abs(q) < 0.000001) break;
				var s = 1.0 / q;
				t -= (x - p)*s;
				t = Math.Clamp(t, 0, 1);
			} 

			return e*(t*t*t) + f*(t*t) + g*t + h;
		}
	}

	/** Represents a single-precision float easing function. */
	public delegate float EasingFunction(float f);

	/** Contains single-precision float easing functions as static methdos. 

		This class is kept for use in shaders, primarily, and for backwards compatibility.

		For easings used in CPU-side Fuse, see `Easing`.
	*/
	public static class EasingFunctions
	{
		public static EasingFunction FromEasing(Easing e)
		{
			if (e is Easing.LinearImpl) return Linear;

			if (e is Easing.QuadraticInImpl) return QuadraticIn;
			if (e is Easing.QuadraticOutImpl) return QuadraticOut;
			if (e is Easing.QuadraticInOutImpl) return QuadraticInOut;

			if (e is Easing.CubicInImpl) return CubicIn;
			if (e is Easing.CubicOutImpl) return CubicOut;
			if (e is Easing.CubicInOutImpl) return CubicInOut;

			if (e is Easing.QuarticInImpl) return QuarticIn;
			if (e is Easing.QuarticOutImpl) return QuarticOut;
			if (e is Easing.QuarticInOutImpl) return QuarticInOut;

			if (e is Easing.QuinticInImpl) return QuinticIn;
			if (e is Easing.QuinticOutImpl) return QuinticOut;
			if (e is Easing.QuinticInOutImpl) return QuinticInOut;

			if (e is Easing.SinusoidalInImpl) return SinusoidalIn;
			if (e is Easing.SinusoidalOutImpl) return SinusoidalOut;
			if (e is Easing.SinusoidalInOutImpl) return SinusoidalInOut;

			if (e is Easing.ExponentialInImpl) return ExponentialIn;
			if (e is Easing.ExponentialOutImpl) return ExponentialOut;
			if (e is Easing.ExponentialInOutImpl) return ExponentialInOut;

			if (e is Easing.CircularInImpl) return CircularIn;
			if (e is Easing.CircularOutImpl) return CircularOut;
			if (e is Easing.CircularInOutImpl) return CircularInOut;

			if (e is Easing.ElasticInImpl) return ElasticIn;
			if (e is Easing.ElasticOutImpl) return ElasticOut;
			if (e is Easing.ElasticInOutImpl) return ElasticInOut;

			if (e is Easing.BackInImpl) return BackIn;
			if (e is Easing.BackOutImpl) return BackOut;
			if (e is Easing.BackInOutImpl) return BackInOut;

			if (e is Easing.BounceInImpl) return BounceIn;
			if (e is Easing.BounceOutImpl) return BounceOut;
			if (e is Easing.BounceInOutImpl) return BounceInOut;

			return Linear;
		}

		public static float Linear(float k)
		{
			return k;
		}

		public static float QuadraticIn(float k)
		{
			return k * k;
		}

		public static float QuadraticOut(float k)
		{
			return k * (2 - k);
		}

		public static float QuadraticInOut(float k)
		{
			k *= 2;
			if (k < 1.0f)
			{
				return 0.5f * k * k;
			}

			k -= 1;
			return -0.5f * (k * (k - 2) - 1);
		}

		public static float CubicIn(float k)
		{
			return k * k * k;
		}

		public static float CubicOut(float k)
		{
			k -= 1;
			return k * k * k + 1;
		}

		public static float CubicInOut(float k)
		{
			k *= 2;
			if (k < 1)
				return 0.5f * k * k * k;

			k -= 2;
			return 0.5f * (k * k * k + 2);
		}

		public static float QuarticIn(float k)
		{
			 return k * k * k * k;
		}

		public static float QuarticOut(float k)
		{
			k -= 1;
			return 1 - (k * k * k * k);
		}

		public static float QuarticInOut(float k)
		{
			k *= 2;
			if (k < 1)
				return 0.5f * k * k * k * k;
			k -= 2;
			return - 0.5f * (k * k * k * k - 2);
		}

		public static float QuinticIn(float k)
		{
			return k * k * k * k * k;
		}

		public static float QuinticOut(float k)
		{
			k -= 1;
			return k * k * k * k * k + 1;
		}

		public static float QuinticInOut(float k)
		{
			k *= 2;
			if (k < 1)
				return 0.5f * k * k * k * k * k;

			k -= 2;
			return 0.5f * (k * k * k * k * k + 2);
		}

		public static float SinusoidalIn(float k)
		{
			return 1 - Math.Cos(k * Math.PIf / 2);
		}

		public static float SinusoidalOut(float k)
		{
			return Math.Sin(k * Math.PIf / 2);
		}

		public static float SinusoidalInOut(float k)
		{
			return 0.5f * (1 - Math.Cos(Math.PIf * k));
		}

		public static float ExponentialIn(float k)
		{
			return k == 0 ? 0.0f : Math.Pow(1024, k - 1);
		}

		public static float ExponentialOut(float k)
		{
			return k == 1 ? 1.0f : 1 - Math.Pow(2, - 10 * k);
		}

		public static float ExponentialInOut(float k)
		{
			if (k == 0)
				return 0;

			if (k == 1)
				return 1;

			k *= 2;
			if (k < 1)
				return 0.5f * Math.Pow(1024, k - 1);

			return 0.5f * (-Math.Pow(2, - 10 * (k - 1)) + 2);
		}

		public static float CircularIn(float k)
		{
			return 1 - Math.Sqrt(1 - k * k);
		}

		public static float CircularOut(float k)
		{
			k = k - 1.0f;
			return Math.Sqrt(1 - (k * k));
		}

		public static float CircularInOut(float k)
		{
			k *= 2;
			if (k < 1)
				return - 0.5f * (Math.Sqrt(1 - k * k) - 1);
			k -= 2;
			return 0.5f * (Math.Sqrt(1 - k * k) + 1);
		}

		public static float ElasticIn(float k)
		{
			if (k == 0)
				return 0;

			if (k == 1)
				return 1;
			k -= 1;
			return -Math.Pow(2, 10 * k) * Math.Sin((k - 0.1f) * (2 * Math.PIf) * 2.5f);
		}

		public static float ElasticOut(float k)
		{
			if (k == 0)
				return 0;

			if (k == 1)
				return 1;

			return Math.Pow(2, - 10 * k) * Math.Sin((k - 0.1f) * (2 * Math.PIf) * 2.5f) + 1;
		}

		public static float ElasticInOut(float k)
		{
			if (k == 0)
				return 0;

			if (k == 1)
				return 1;

			k = k * 2 - 1;
			if (k < 0)
				return - 0.5f * Math.Pow(2, 10 * k) * Math.Sin((k - 0.1f) * (2 * Math.PIf) * 2.5f);
			return Math.Pow(2, -10 * k) * Math.Sin((k - 0.1f) * (2 * Math.PIf) * 2.5f) * 0.5f + 1;
		}

		public static float BackIn(float k)
		{
			var s = 1.70158f;
			return k * k * ((s + 1) * k - s);
		}

		public static float BackOut(float k)
		{
			var s = 1.70158f;
			k = k - 1.0f;
			return k * k * ((s + 1) * k + s) + 1;
		}

		public static float BackInOut(float k)
		{
			var s = 1.70158f * 1.525f;

			k *= 2;
			if (k < 1)
				return 0.5f * (k * k * ((s + 1) * k - s));

			k -= 2;
			return 0.5f * (k * k * ((s + 1) * k + s) + 2);
		}

		public static float BounceIn(float k)
		{
			return 1 - EasingFunctions.BounceOut(1 - k);
		}

		public static float BounceOut(float k)
		{
			if (k < (1 / 2.75f))
			{
				return 7.5625f * k * k;
			}
			else if (k < (2 / 2.75f))
			{
				k -= 1.5f / 2.75f;
				return 7.5625f * k * k + 0.75f;
			}
			else if (k < (2.5f / 2.75f))
			{
				k -= 2.25f / 2.75f;
				return 7.562f * k * k + 0.9375f;
			}
			else
			{
				k -= 2.625f / 2.75f;
				return 7.5625f * k * k + 0.984375f;
			}
		}

		public static float BounceInOut(float k)
		{
			if (k < 0.5f)
				return EasingFunctions.BounceIn(k * 2) * 0.5f;
			return EasingFunctions.BounceOut(k * 2 - 1) * 0.5f + 0.5f;
		}
	}
}
