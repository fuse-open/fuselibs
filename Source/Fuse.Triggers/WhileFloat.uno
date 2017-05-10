using Uno;
using Uno.UX;

namespace Fuse.Triggers
{
	/** Active when the `float` `Value` fulfills some criteria. */
	public sealed class WhileFloat : WhileValue<float>
	{
		/** The float value to compare. */
		public new float Value
		{
			get { return base.Value; }
			set { base.Value = value; }
		}
		
		enum Range
		{
			Open,
			Exclusive,
			Inclusive,
		}
		
		float2 _compare;
		Range _low = Range.Open, _high = Range.Open;
		
		/** Active when the float `Value` is less than the provided value. */
		public float LessThan
		{
			get { return _compare.Y; }
			set
			{
				_compare.Y = value;
				_high = Range.Exclusive;
				UpdateState();
			}
		}
		
		/** Active when the float `Value` is less than or equal to the provided value. */
		public float LessThanEqual
		{
			get { return _compare.Y; }
			set
			{
				_compare.Y = value;
				_high = Range.Inclusive;
				UpdateState();
			}
		}
		
		/** Active when the float `Value` is greater than the provided value. */
		public float GreaterThan
		{
			get { return _compare.X; }
			set
			{
				_compare.X = value;
				_low = Range.Exclusive;
				UpdateState();
			}
		}
		
		/** Active when the float `Value` is greater than or equal to the provided value. */
		public float GreaterThanEqual
		{
			get { return _compare.X; }
			set
			{
				_compare.X = value;
				_low = Range.Inclusive;
				UpdateState();
			}
		}
		
		protected override bool IsOn
		{
			get
			{
				if (_low == Range.Exclusive && (Value <= _compare.X))
					return false;
				if (_low == Range.Inclusive && (Value < _compare.X))
					return false;
				if (_high == Range.Exclusive && (Value >= _compare.Y))
					return false;
				if (_high == Range.Inclusive && (Value > _compare.Y))
					return false;
				
				return true;
			}
		}
	}
}
