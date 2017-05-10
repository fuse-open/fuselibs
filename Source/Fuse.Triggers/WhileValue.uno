using Uno;
using Uno.UX;

namespace Fuse.Triggers
{
	static class WhileValueStatic
	{
		static internal bool _deprecatedNote;
	}
	
	public abstract class WhileValue<T> : WhileTrigger, IPulseTrigger
	{
		T _value;
		bool _hasValue;
		public T Value
		{
			get
			{
				if (_hasValue) return _value;
				if (_obj != null) return _obj.Value;
				return _value;
			}
			set
			{
				if (!_hasValue || !object.Equals(_value,value))
				{
					_hasValue = true;
					_value = value;
					SetActive(IsOn);
				}
			}
		}

		IValue<T> _source;
		public IValue<T> Source
		{
			get { return _source; }
			set { _source = value; 	}
		}

		public event ValueChangedHandler<T> ValueChanged;

		public new void Pulse()
		{
			if (!WhileValueStatic._deprecatedNote)
			{
				Fuse.Diagnostics.Deprecated( 
					"`Pulse` on a `WhileValue` will be removed, create a `Timeline` instead.",
					this);
				WhileValueStatic._deprecatedNote = true;
			}
				
			if (IsOn != Invert)
				base.InversePulse();
			else
				base.Pulse();
		}
		
		static IValue<T> FindValueNode(Node n)
		{
			if (n is IValue<T>) return (IValue<T>)n;
			if (n.ContextParent != null) return FindValueNode(n.ContextParent);
			return null;
		}

		IValue<T> _obj;
		protected override void OnRooted()
		{
			base.OnRooted();
			_obj = Source ?? FindValueNode(Parent);
			if (_obj != null) _obj.ValueChanged += OnValueChanged;
			SetActive(IsOn);
		}

		protected override void OnUnrooted()
		{
			if (_obj != null)
			{
				_obj.ValueChanged -= OnValueChanged;
				_obj = null;
			}
			base.OnUnrooted();
		}

		void OnValueChanged(object s, ValueChangedArgs<T> a)
		{
			SetActive(IsOn);
			if (ValueChanged != null)
				ValueChanged(this, a);
		}

		protected void UpdateState()
		{
			if (!IsRootingCompleted)
				return;
			SetActive(IsOn);
		}

		protected abstract bool IsOn { get; }
	}
}
