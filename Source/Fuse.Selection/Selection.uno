using Uno;
using Uno.UX;
using Uno.Collections;

using Fuse.Reactive;

namespace Fuse.Selection
{
	public enum SelectionReplace
	{
		Oldest,
		Newest,
		None,
	}

	/**
		@Selection is used to create a selection control, such as an item list, radio buttons, or picker. The @Selection itself defines the selection, managing the high-level behaviour and tracking the current value. A variety of @Selectable objects define which items can be selected.
		
		## Introduction to the Selection API 
		
		<iframe width="560" height="315" src="https://www.youtube.com/embed/Ngil94H-Mk4" frameborder="0" allowfullscreen></iframe>
		
		The selection is associated with the node in which it appears. For example:
		
			<Panel>
				<Selection/>
			</Panel>
			
		The @Panel is now considered to be a selection control. Behaviours and triggers, such as @Selectable and @Selected, that are descendents of this panel will find this `Selection` behavior.
		
		The @(Selectable) node is used to make a child of a selection control selectable. When assigned to a nodes, it will iterate through the controls parents until it finds a selection control.

		The Selection API's functions are split between user-interaction and programming APIs. The user interaction functions are constrained to the requirements of the Selection, such as `MaxCount` and `MinCount`. The programmatic functions can set whatever state they want; they are not constrained. This makes it easy to create value bindings and JavaScript driven behaviour without worrying about initialization order.
		
		## Example
		
		@examples Docs/example.md
	*/
	public partial class Selection : Behavior, Reactive.IObserver
	{
		static internal Selection TryFindSelection(Node v)
		{
			while (v != null)
			{
				var vs = v as Visual;
				if (vs != null)
				{
					var l = vs.FirstChild<Selection>();
					if (l != null)
						return l;
				}
					
				v = v.ContextParent;
			}
			return null;
		}

		static internal bool TryFindSelectable( Node n, out Selectable selectable, out Selection selection )
		{
			selectable = null;
			selection = null;
			
			while (n != null)
			{
				var vs = n as Visual;
				if (vs != null)
				{
					if (selectable == null)
						selectable = vs.FirstChild<Selectable>();
					else
						selection = vs.FirstChild<Selection>();
					
					if (selectable != null && selection != null)
						return true;
				}
				
				n = n.ContextParent;
			}
			
			selectable = null;
			selection = null;
			return false;
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			OnObservableValuesChanged();
		}
		
		protected override void OnUnrooted()
		{
			ClearSubscription();
			base.OnUnrooted();
		}
		
		SelectionReplace _replace = SelectionReplace.Oldest;
		/**
			Specifies what happens when the user selects an item that would exceed the MaxCount.
		*/
		public SelectionReplace Replace
		{
			get { return _replace; }
			set { _replace = value; }
		}
		
		int _minCount = 0;
		/**
			The minimum number of items the user is allowed to select. If they attempt to deselect and item and go below this count the deselect will be ignored.
		*/
		public int MinCount
		{
			get { return _minCount; }
			set
			{
				if (value == _minCount)
					return;
				
				_minCount = value;
			}
		}
		
		bool _hasMaxCount = false;
		int _maxCount;
		/**
			The maximum number of items the user is allowed to select. If they attempt to select more items then `Replace` decides what happens.
		*/
		public int MaxCount
		{
			get { return _maxCount; }
			set
			{
				if (_hasMaxCount && value == _maxCount)
					return;
				
				if (value < 1)
				{
					Fuse.Diagnostics.UserError( "MaxCount must >= 1", this );
					return;
				}
				
				_hasMaxCount = true;
				_maxCount = value;
			}
		}
		
		/**
			Is a `MaxCount` defined on this `Selection`.
		*/
		public bool HasMaxCount
		{
			get { return _hasMaxCount; }
		}

		List<string> _values = new List<string>();
		
		/**
			@return true if the Selectable is currently selected.
		*/
		public bool IsSelected(Selectable b)
		{
			// "nothing" can never be selected
			if (string.IsNullOrEmpty(b.Value))
				return false;
				
			return _values.Contains(b.Value);
		}
		
		/**
			Toggles the selection status of this Selectable.
			
			This respects the user-interaction constraints.
		*/
		public void Toggle(Selectable b)
		{
			Toggle(b.Value);
		}
		
		void Toggle(string value)
		{
			if (_values.Contains(value))
				Remove(value);
			else
				Add(value);
		}
		
		/**
			Adds a Selectable to the Selection. If it is already added it won't be added a second time.
			
			This respects the user-interaction constraints. If too many items are added `Replace` defines what happens.
		*/
		public void Add(Selectable b)
		{
			Add(b.Value);
		}
		
		/**
			Removes a Selectable from the Selection. If it is not in the selection then nothing happens.
			
			This respects the user-interaction constraints. The item will not be removed if it would go below `MinCount`.
		*/
		public void Remove(Selectable b)
		{
			Remove(b.Value);
		}

		/**
			Clears all items from the selection.
			
			This ignores user-interaction constraints.
		*/
		public void Clear()
		{
			_values.Clear();
			OnSelectionChanged(How.API);
		}
		
		/**
			Adds a Selectable to the Selection even if would violate the user-interaction constraints. It will however not add the same value twice.
		*/
		public void ForceAdd(Selectable b)
		{
			ForceAdd(b.Value);
		}
		
		void ForceAdd(string value)
		{
			if (!_values.Contains(value))
			{
				_values.Add(value);
				OnSelectionChanged(How.API);
			}
		}
		
		/**
			Removes a Selectable form the Selection even if it would violated the user-interaction constraints (such as `MinCount`).
		*/
		public void ForceRemove(Selectable b)
		{
			ForceRemove(b.Value);
		}
		
		void ForceRemove(string value)
		{
			if (_values.Contains(value))
			{
				_values.Remove(value);
				OnSelectionChanged(How.API);
			}
		}
		
		/**
			The number of items currently selected.
		*/
		public int SelectedCount
		{
			get { return _values.Count; }
		}
		
		public static Selector ValueName = new Selector("Value");
		
		[UXOriginSetter("SetValue")]
		/**
			The string value of the item curerntly selected. If multiple items are selected then it will be value of the oldest item selected.
			
			This is suitable for use with selections that allow only one item to be selected, such as radio buttons. It can be used directly in a binding:
			
				<Selection Value="{jsValue}"/>
		*/
		public string Value
		{
			get
			{
				return _values.Count > 0 ? _values[0] : "";
			}
			set { SetValue(value, null); }
		}
		public void SetValue(string value, IPropertyListener origin)
		{
			if (value == Value)
				return;

			var has = false;
			for (int i=_values.Count-1; i>=0; i--)
			{
				if (_values[i] != value)
					Remove(_values[i]);
				else
					has = true;
			}
			
			if (!has)
				Add(value);
		}
		
		void Remove(string value)
		{
			if (!_values.Contains(value))
				return;
				
			if (_values.Count-1 < MinCount)
				return;
				
			_values.Remove(value);
			OnSelectionChanged(How.API);
		}
		
		void Add(string value)
		{
			if (_values.Contains(value))
				return;
				
			if (HasMaxCount && _values.Count+1 > MaxCount)
			{
				if (Replace == SelectionReplace.None || MaxCount < 1 /*safety for below*/)
					return;
					
				if (Replace == SelectionReplace.Oldest)
					_values.RemoveAt(0);
				else
					_values.RemoveAt(_values.Count-1);
			}
			
			_values.Add(value);
			OnSelectionChanged(How.API);
		}
		
		/**
			Raised whenever the selection state changes.
		*/
		public event EventHandler SelectionChanged;
		
		enum How
		{
			API,
			Observable,
		}

		class ListWrapper: IArray
		{
			readonly List<string> _list;
			public ListWrapper(List<string> list)
			{
				_list = list;
			}
			public int Length { get { return _list.Count; } }
			public object this [int index] { get { return _list[index]; } }
		}
		
		void OnSelectionChanged(How how)
		{
			OnPropertyChanged(ValueName);
			if (SelectionChanged != null)
				SelectionChanged(this, EventArgs.Empty);
				
			if (how == How.API && _subscription != null)
			{
				var sub = _subscription as ISubscription;
				if (sub != null) sub.ReplaceAllExclusive( new ListWrapper(_values) );
				else Diagnostics.UserWarning("Selection changed, but the bound collection is not writeable.", this);
			}
		}
		
		/*
			Allows a selectable to change value without the selection state changes.
		*/
		internal void ModifyValue(string old, string nw)
		{
			if (string.IsNullOrEmpty(old) || string.IsNullOrEmpty(nw))
				return;
				
			if (_values.Contains(old))
			{
				_values.Remove(old);
				_values.Add(nw);
				OnSelectionChanged(How.API);
			}
		}
		
		Reactive.IObservableArray _observableValues;
		/**
			The current list of selected values. This should be bound to an `IObservableArray` (e.g `FuseJS/Observable`) order to create a 2-way interface for the selected items.
			
			@examples Docs/example.md
		*/
		public object Values
		{
			get { return _observableValues; }
			set 
			{ 
				var q = value as Reactive.IObservableArray;
				if (value != null && q == null)
				{
					Fuse.Diagnostics.UserError( "`Values` must be an IObservableArray", this );
					return;
				}
				
				if (_observableValues != q)
				{
					_observableValues = q;
					OnObservableValuesChanged();
				}
			}
		}
		
		void OnObservableValuesChanged()
		{
			ClearSubscription();
			if (_observableValues == null)
				return;

			OnNewAll(_observableValues);
				
			_subscription = _observableValues.Subscribe(this);
		}
		
		IDisposable _subscription;
		void ClearSubscription()
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
			}
		}

		void Reactive.IObserver.OnClear()
		{
			_values.Clear();
			OnSelectionChanged(How.Observable);
		}

		void Reactive.IObserver.OnNewAll(IArray values)
		{
			OnNewAll(values);
		}

		void OnNewAll(IArray values)
		{
			_values.Clear();
			for (int i=0; i < values.Length; ++i)
				_values.Add( Marshal.ToType<string>( values[i] ) );
			OnSelectionChanged(How.Observable);
		}
		
		void Reactive.IObserver.OnNewAt(int index, object newValue)
		{
			if (index <0 || index >= _values.Count)
			{
				Fuse.Diagnostics.InternalError( "removing invalid observable item", this );
				return;
			}
			_values[index] = Marshal.ToType<string>(newValue);
			OnSelectionChanged(How.Observable);
		}
		
		void Reactive.IObserver.OnSet(object newValue)
		{
			_values.Clear();
			_values.Add( Marshal.ToType<string>(newValue) );
			OnSelectionChanged(How.Observable);
		}
		
		void Reactive.IObserver.OnAdd(object addedValue)
		{
			_values.Add( Marshal.ToType<string>(addedValue) );
			OnSelectionChanged(How.Observable);
		}
		
		void Reactive.IObserver.OnRemoveAt(int index)
		{
			if (index <0 || index >= _values.Count)
			{
				Fuse.Diagnostics.InternalError( "removing invalid observable item", this );
				return;
			}
			_values.RemoveAt(index);
			OnSelectionChanged(How.Observable);
		}
		
		void Reactive.IObserver.OnInsertAt(int index, object value)
		{
			if (index <0 || index > _values.Count)
			{
				Fuse.Diagnostics.InternalError( "removing invalid observable item", this );
				return;
			}
			_values.Insert(index, Marshal.ToType<string>(value) );
			OnSelectionChanged(How.Observable);
		}
		
		void Reactive.IObserver.OnFailed(string message)
		{
			(this as Reactive.IObserver).OnClear();
			Fuse.Diagnostics.InternalError( message, this );
		}
		
		internal string Test_JoinValues()
		{
			string q = "";
			for (int i=0; i < _values.Count; ++i)
			{
				if (i>0) q += ",";
				q += _values[i];
			}
			return q;
		}
	}
}
