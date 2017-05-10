using Uno;
using Uno.UX;

namespace Fuse.Triggers
{
	public enum WhileStringTest
	{
		/** No logical test is done */
		None,
		/** The string value is of 0-length */
		IsEmpty,
		/** The string value is not empty, at least 1 long */
		IsNotEmpty,
		/** The string value is equal to `Compare`  */
		Equals,
		/** The string value contains `Compare` */
		Contains,
	}
	
	/** Activate when the condition on the string value is true */
	public sealed class WhileString : WhileValue<string>
	{
		WhileStringTest _test = WhileStringTest.None;
		public WhileStringTest Test
		{
			get { return _test; }
			set 
			{
				if (_test != value)
				{
					_test = value;
					UpdateState();
				}
			}
		}
		
		string _compare;
		/** 
			The value used in comparison.
			
			This is not used by all `Type` values.
		*/
		public string Compare
		{
			get { return _compare; }
			set
			{
				if (_compare != value)
				{
					_compare = value;
					UpdateState();
				}
			}
		}
		
		bool _caseSensitive = true;
		/**
			If `false` then the strings will be compared in a case-insensitve manner.
			
			The default is `true`.
		*/
		public bool CaseSensitive
		{
			get { return _caseSensitive; }
			set
			{
				if (value != _caseSensitive)
				{
					_caseSensitive = value;
					UpdateState();
				}
			}
		}

		/** Shortcut to set `Type="Equal" Compare="value"` */
		new public string Equals
		{
			get { return Compare; }
			set
			{
				Compare = value;
				Test = WhileStringTest.Equals;
			}
		}
		
		/** Shortcut to set `Type="Contain" Compare="value"` */
		public string Contains
		{
			get { return Compare; }
			set 
			{
				Compare = value;
				Test = WhileStringTest.Contains;
			}
		}

		int _minLength, _maxLength;
		bool _hasMinLength, _hasMaxLength;
		public int MinLength
		{
			get { return _minLength; }
			set
			{
				if (!_hasMinLength || value != _minLength)
				{
					_hasMinLength = true;
					_minLength = value;
					UpdateState();
				}
			}
		}
		
		public int MaxLength
		{
			get { return _maxLength; }
			set
			{
				if (!_hasMaxLength || value != _maxLength)
				{
					_hasMaxLength = true;
					_maxLength = value;
					UpdateState();
				}
			}
		}
		
		protected override bool IsOn
		{
			get
			{
				//should use `.Normalize` here, but Uno doesn't have it, dotNet does
				var value = Value ?? "";
				var compare = Compare ?? "";

				if (_hasMaxLength && value.Length > MaxLength)
					return false;
					
				if (_hasMinLength && value.Length < MinLength)
					return false;
					
				if (!CaseSensitive)
				{
					value = value.ToLower();
					compare = compare.ToLower();
				}

				bool c = true;
				switch (Test)
				{
					case WhileStringTest.None:	
						c = true;
						break;
						
					case WhileStringTest.IsEmpty:
						c = value.Length == 0;
						break;
						
					case WhileStringTest.IsNotEmpty:
						c = value.Length > 0;
						break;
						
					case WhileStringTest.Equals:
						c = value == compare;
						break;
						
					case WhileStringTest.Contains:
						c = value.IndexOf(compare) != -1;
						break;
				}
				
				if (!c)
					return false;
					
				return true;
			}
		}
	}
}

