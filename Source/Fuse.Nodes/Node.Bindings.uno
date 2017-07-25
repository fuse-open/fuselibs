using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse
{
	/*
		Optimized implementation of IList<Binding> that creates no extra objects unless needed
	*/
	public partial class Node
	{
		[UXContent]
		/** The list of bindings belonging to this node. */
		public IList<Binding> Bindings { get { return this; } }

		object _bindings;

		Binding Binding { get { return _bindings as Binding; } }
		List<Binding> BindingList { get { return _bindings as List<Binding>; } }

		void MakeBindingList(Binding newItem)
		{
			var list = new List<Binding>();
			var oldItem = _bindings as Binding;
			if (oldItem != null) list.Add(oldItem);
			if (newItem != null) list.Add(newItem);
			_bindings = list;
		}

		void Root(Binding b) 
		{ 
			if (IsRootingStarted) b.Root(this);
		}

		void Unroot(Binding b) 
		{ 
			if (IsRootingStarted) b.Unroot();
		}

		void RootBindings()
		{
			if (_bindings == null) return;

			if (Binding != null) Binding.Root(this);
			else
			{
				var bl = BindingList;
				for (int i = 0; i < bl.Count; i++) bl[i].Root(this);
			}
		}

		void UnrootBindings()
		{
			if (_bindings == null) return;

			if (Binding != null) Binding.Unroot();
			else
			{
				var bl = BindingList;
				for (int i = 0; i < bl.Count; i++) bl[i].Unroot();
			}
		}

		void ICollection<Binding>.Clear()
		{
			if (IsRootingStarted) UnrootBindings();			
			_bindings = null;
		}

		public void Add(Binding item)
		{
			if (_bindings == null) _bindings = item;
			else if (_bindings is Binding) MakeBindingList(item); 
			else BindingList.Add(item);

			Root(item);
		}

		public bool Remove(Binding item)
		{
			Unroot(item);

			if (_bindings == item) { _bindings = null; return true; }
			if (_bindings == null || _bindings is Binding) return false;
			
			return BindingList.Remove(item);
		}

		bool ICollection<Binding>.Contains(Binding item)
		{
			if (_bindings == item) return true;
			var bl = BindingList;
			if (bl != null) return bl.Contains(item);
			return false;
		}

		int ICollection<Binding>.Count 
		{ 
			get
			{
				if (_bindings == null) return 0;
				if (_bindings is Binding) return 1;
				return BindingList.Count;
			} 
		}

		public void Insert(int index, Binding item)
		{
			if (_bindings == null) _bindings = item;
			else
			{
				if (_bindings is Binding) MakeBindingList(null);
				BindingList.Insert(index, item);
			}

			Root(item);
		}

		void IList<Binding>.RemoveAt(int index)
		{
			if (_bindings == null) throw new Exception();

			var b = Binding;
			if (b != null)
			{
				if (index != 0) throw new Exception();
				Unroot(b);
				_bindings = null;
			}
			else
			{
				Unroot(BindingList[index]);
				BindingList.RemoveAt(index);
			}
		}

		Binding IList<Binding>.this[int index]
		{
			get
			{
				if (_bindings == null) throw new Exception();
				
				var b = Binding;
				if (b != null)
				{
					if (index != 0) throw new Exception();
					return b;
				}
				else
				{
					return BindingList[index];
				}
			}
		}

		static IEnumerable<Binding> _emptyBindings = new Binding[0];

		IEnumerator<Binding> IEnumerable<Binding>.GetEnumerator()
		{
			if (_bindings == null) return _emptyBindings.GetEnumerator();
			if (_bindings is Binding) MakeBindingList(null);
			return BindingList.GetEnumerator();
		}
	}
}
