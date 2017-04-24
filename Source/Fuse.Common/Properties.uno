using Uno;

namespace Fuse
{
	public class PropertyHandle
	{
		internal PropertyHandle()  {}
	}

	public interface IProperties
	{
		Properties Properties { get; }
	}

	public sealed class Properties
	{
		Properties _next;
		PropertyHandle _handle;
		object _value;

		public static PropertyHandle CreateHandle() 
		{ 
			return new PropertyHandle();
		}

		public object Get(PropertyHandle handle)
		{
			if (_handle == handle) return _value;
			if (_next != null) return _next.Get(handle);
			return null;
		}

		public bool TryGet(PropertyHandle handle, out object val)
		{
			if (_handle == handle) { val = _value; return true; }
			if (_next != null) return _next.TryGet(handle, out val);
			val = null;
			return false;
		}
		
		public bool Has(PropertyHandle handle)
		{
			if (_handle == handle) return true;
			if (_next != null) return _next.Has(handle);
			return false;
		}

		public void Set(PropertyHandle handle, object val)
		{
			if (_handle == null)
			{
				_handle = handle;
				_value = val;
			}
			else if (_handle == handle)
			{
				_value = val;
			}
			else 
			{
				if (_next == null) _next = new Properties();
				_next.Set(handle, val);
			}
		}

		public void AddToList(PropertyHandle handle, object val)
		{
			if (_handle == null)
			{
				_handle = handle;
				_value = val;
			}
			else if (_next == null)
			{
				_next = new Properties();
				_next.AddToList(handle, val);
			}
			else
			{
				_next.AddToList(handle, val);
			}
		}

		public void RemoveFromList(PropertyHandle handle, object val)
		{
			Clear(handle, val, false);
		}

		public void RemoveAllFromList(PropertyHandle handle, object val)
		{
			Clear(handle, val, true);
		}

		public object[] ToArray(PropertyHandle handle)
		{
			if (_handle == null) return new object[0];

			var list = new Uno.Collections.List<object>();

			var p = this;

			while (p != null)
			{
				if (p._handle == handle)
				{
					list.Add(p._value);
				}

				p = p._next;
			}

			return list.ToArray();
		}

		public void ForeachInList(PropertyHandle handle, Action<object, object> action, object state)
		{
			if (_handle == null) return;

			var p = this;

			while (p != null)
			{
				if (p._handle == handle)
				{
					action(p._value, state);
				}

				p = p._next;
			}
		}

		public void ForeachInList(PropertyHandle handle, Action<object, object[]> action, params object[] state)
		{
			if (_handle == null) return;

			var p = this;

			while (p != null)
			{
				if (p._handle == handle)
				{
					action(p._value, state);
				}

				p = p._next;
			}
		}

		public void Clear(PropertyHandle handle)
		{
			Clear(handle, NoValue, true);
		}

		static object NoValue = new object();

		void Clear(PropertyHandle handle, object val, bool all)
		{
			if (_handle == null) return;
		
			var p = this;
			var previous = (Properties)null;

			while (p != null)
			{
				if (p._handle == handle && (val == NoValue || val.Equals(p._value)))
				{
					if (previous == null)
					{
						if (p._next == null)
						{
							p._handle = null;
							p._value = null;
							break;
						}
						else
						{
							// Trick to delete head of linked list
							// Shift next node to overwrite this one
							p._handle = p._next._handle;
							p._value = p._next._value;
							p._next = p._next._next;
							if (all) continue;
							else break;
						}
					}
					else
					{
						previous._next = p._next;
						p = p._next;
						if (all) continue;
						else break;
					}
				}
				else
				{
					previous = p;
					p = p._next;
				}

			}
		}

	}
}