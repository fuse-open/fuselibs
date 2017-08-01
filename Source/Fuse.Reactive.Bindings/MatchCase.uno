using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Compares a value with a set of constants, and activates/deactivates visual trees associated with those constants.
		
		`Match` (in conjunction with @Case) is useful when you want to display one of a number of different visuals
		based on a certain value. You can think of it like pattern matching and/or switch/case constructs from your
		favorite programming language.

		## Example

			<JavaScript>
				module.exports = {
					active: "blue"
				};
			</JavaScript>
			<Match Value="{active}">
				<Case String="red">
					<Rectangle Fill="#f00" Height="50" Width="50" />
				</Case>
				<Case String="blue">
					<Rectangle Fill="#00f" Height="50" Width="50" />
				</Case>
			</Match>
	*/
	public class Match: Behavior, IObserver
	{
		RootableList<Case> _cases;

		/** @advanced
		*/
		[UXContent]
		public IList<Case> Cases
		{
			get
			{
				if (_cases == null)
				{
					_cases = new RootableList<Case>();
					if (IsRootingCompleted)
						_cases.Subscribe(OnCaseAdded, OnCaseRemoved);
				}
				return _cases;
			}
		}

		void OnCaseAdded(Case c)
		{
			c.Root(this);
			Invalidate();
		}

		void OnCaseRemoved(Case c)
		{
			c.Unroot();
			Invalidate();
		}

		void IObserver.OnSet(object newValue)
		{
			_realValue = newValue;
			Invalidate();
		}

		void IObserver.OnClear()
		{
			
		}

		void IObserver.OnAdd(object addedValue)
		{
			throw new Exception("Not handled: OnAdd");
		}

		void IObserver.OnNewAt(int index, object value)
		{
			throw new Exception("Not handled: OnNewAt");
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			throw new Exception("Not handled: InsertAt");
		}

		void IObserver.OnFailed(string message)
		{
			(this as IObserver).OnClear();
			// TODO
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (values.Length == 0)
			{
				_realValue = null;
				Invalidate();
				return;
			}

			throw new Exception("<Match> can not be used on lists (received OnNewAll)");
		}

		void IObserver.OnRemoveAt(int index)
		{
			throw new Exception("<Match> can not be used on lists (received OnRemoveAt)");
		}

		IDisposable _subscription;

		object _realValue;
		object _value;
		/** Specifies the value that will be matched on.
		*/
		public object Value
		{
			get { return _value; }
			set
			{
				if (_value != value)
				{
					_value = value;

					if (_subscription != null)
					{
						_subscription.Dispose();
						_subscription = null;
					}

					if (_value is IObservable)
					{
						// Special treatment for IObservable which can be interpreted as a single value
						var obs = (IObservable)_value;
						if (obs.Length > 0) _realValue = obs[0];
						_subscription = obs.Subscribe(this);
					}
					else
					{
						_realValue = _value;
					}

					Invalidate();
				}

			}
		}

		/** Specifies the value that will be matched on as a string.
		*/
		public string String
		{
			get { return Value as string; }
			set { Value = value; }
		}

		/** Specifies the value that will be matched on as a number.
		*/
		public double Number
		{
			get { return Value is double ? (double)Value : 0.0; }
			set { Value = value; }
		}

		/** Specifies the value that will be matched on as an integer.
		*/
		public int Integer
		{
			get { return Value is int ? (int)Value : 0; }
			set { Value = value; }
		}

		/** Specifies the value that will be matched on as a boolean.
		*/
		public bool Bool
		{
			get { return Value is bool ? (bool)Value : false; }
			set { Value = value; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_cases.RootSubscribe(OnCaseAdded, OnCaseRemoved);
			Update();
		}

		protected override void OnUnrooted()
		{
			RemoveElements();
			_cases.RootUnsubscribe();
			base.OnUnrooted();
		}

		List<Node> _elements = new List<Node>();

		Case _oldCase;

		internal void Invalidate()
		{
			if (!IsRootingCompleted) return;

			Update();
		}

		void Update()
		{
			var newCase = SelectCase();
			if (newCase != _oldCase)
			{
				RemoveElements();
				if (newCase != null)
					AddElements(newCase);
			}
		}

		Case SelectCase()
		{
			Case def = null;
			foreach (var c in _cases)
			{
				if (c.Value != null && c.Value.Equals(_realValue)) return c;
				if (c.IsDefault) def = c;
			}
			return def;
		}

		void RemoveElements()
		{
			_oldCase = null;
			foreach (var e in _elements)
			{
				if (e.OverrideContextParent == this) e.OverrideContextParent = null;
				Parent.BeginRemoveChild(e);
			}

			_elements.Clear();
		}

		void AddElements(Case c)
		{
			if (c != null)
			{
				foreach (var f in c.Factories)
				{
					var elm = f.New() as Node;
					if (elm != null)
					{
						elm.OverrideContextParent = elm.OverrideContextParent ?? this;
						_elements.Add(elm);
					}

				}
				
				Parent.InsertNodesAfter(this, _elements.GetEnumerator());
			}
			_oldCase = c;
		}
		
		internal override Node GetLastNodeInGroup()
		{
			if (_elements.Count == 0)
				return this;
			return _elements[_elements.Count-1];
		}
	}

	[UXContentMode("Template")]
	/** Specifies a constant and an associated visual tree that will be used with @Match.
		
		See @Match for more info.
	*/
	public class Case
	{
		Match _match;
		bool IsRooted { get { return _match != null; } }
		
		internal void Root(Match match)
		{
			if (_match != null) throw new Exception("Case already has a Match");
			_match = match;
			
			if (_factories != null)
				_factories.Subscribe(OnFactoriesChanged, OnFactoriesChanged);
		}
		
		internal void Unroot()
		{
			if (_factories != null)
				_factories.Unsubscribe();
				
			_match = null;
		}

		object _value;

		/** Specifies a constant that will be matched against.
		*/
		public object Value
		{
			get { return _value; }
			set
			{
				if (_value != value)
				{
					_value = value;
					Invalidate();
				}
			}
		}

		/** Specifies a string constant that will be matched against.
		*/
		public string String
		{
			get { return _value as string; }
			set { Value = value; }
		}

		/** Specifies a numeric constant that will be matched against.
		*/
		public double Number
		{
			get { return _value is double ? (double)_value : 0; }
			set { Value = value; }
		}

		/** Specifies a boolean constant that will be matched against.
		*/
		public bool Bool
		{
			get { return _value is bool ? (bool)_value : false; }
			set { Value = value; }
		}

		/** Specifies whether or not this `Case` is the default `Case` within a `Match`.
		*/
		public bool IsDefault
		{
			get;
			set;
		}


		RootableList<Template> _factories;

		/** @advanced
		*/
		[UXPrimary]
		public IList<Template> Factories
		{
			get
			{
				if (_factories == null)
				{
					_factories = new RootableList<Template>();
					if (IsRooted)
						_factories.Subscribe(OnFactoriesChanged, OnFactoriesChanged);
				}
				return _factories;
			}
		}

		void OnFactoriesChanged(Template f)
		{
			Invalidate();
		}

		void Invalidate()
		{
			if (_match != null) _match.Invalidate();
		}
	}
}
