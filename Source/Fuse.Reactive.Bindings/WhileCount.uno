using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Triggers;

namespace Fuse.Reactive
{
	/**
		Active when the number of items in a collection fulfills some criteria.

		The collection is specified with `Items`.

		`WhileCount` accepts a combination of properties that form an open or closed range of numbers to test against. The trigger is active while the count of items matches.
		
		- `EqualTo` is used on its own and the item count must match this number.
		- Using just `LessThan` or `LessThanEqual` the count of items must be less than, or less than or equal to, this number.
		- Using juse `GreaterThan` or `GreaterThanEqual` the count of items must be greater than, or greater than or equal to, this number.
		- Using both a `LessThan` or `LessThanEqual` and `GreaterThan` or `GreaterThanEqual` creates a closed range to compare. The number of items must be within this range.

		This example shows how to use @WhileCount and @WhileEmpty with an @Observable:

			<JavaScript>
				var Observable = require("FuseJS/Observable");
				module.exports = {
					friends: Observable("Alice", "Bob", "Courtney")
				}
			</JavaScript>
			<WhileEmpty Items="{friends}">
				<Text>Your friends list is empty.</Text>
			</WhileEmpty>
			<WhileCount Items="{friends}" EqualTo="1">
				<Text>Your have 1 friend.</Text>
			</WhileCount>
			<WhileCount Items="{friends}" GreaterThan="3" >
				<Text>You have more than 3 friends.</Text>
			</WhileCount>
			<WhileCount Items="{friends}" GreaterThanEqual="1" LessThanEqual="3" >
				<Text>You have 1-3 friends.</Text>
			</WhileCount>
			<WhileCount Items="{friends}" GreaterThanEqual="2" LessThanEqual="5" Invert="true">
				<Text>You do not have 2-5 friends.</Text>
			</WhileCount>
	*/
	public class WhileCount : WhileTrigger, IObserver
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			OnItemsChanged();
		}

		protected override void OnUnrooted()
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
			}

			base.OnUnrooted();
		}

		object _items;

		/** Specifies the collection whose item count will be compared.
		*/
		public object Items
		{
			get { return _items; }
			set
			{
				if (_items != value)
				{
					_items = value;
					OnItemsChanged();
				}
			}
		}

		void OnItemsChanged()
		{
			if (!IsRootingStarted)
				return;
				
			if (_subscription != null) _subscription.Dispose();
			
			var obs = _items as IObservableArray;
			if (obs != null)
				_subscription = obs.Subscribe(this);
			
			UpdateState();
		}

		void UpdateState()
		{
			if (!IsRootingStarted)
				return;

			var e = _items as object[];
			if (e != null)
			{
				Assess(e.Length);
				return;
			}
			
			var obs = _items as IObservableArray;
			if (obs != null)
			{
				Assess(obs.Length);
				return;
			}
			
			var arr = _items as IArray;
			if (arr != null) 
			{
				Assess(arr.Length);
				return;
			}
			
			Assess(0);
		}

		int _oldCount;

		void Assess(int count)
		{
			_oldCount = count;
			SetActive(IsOn(_oldCount));
		}
		
		bool IsOn(int count)
		{
			if (_low == Range.Exclusive && (count <= _compare.X))
				return false;
			if (_low == Range.Inclusive && (count < _compare.X))
				return false;
			if (_high == Range.Exclusive && (count >= _compare.Y))
				return false;
			if (_high == Range.Inclusive && (count > _compare.Y))
				return false;
			
			return true;
		}

		enum Range
		{
			Open,
			Exclusive,
			Inclusive,
		}
		
		int2 _compare;
		Range _low = Range.Open, _high = Range.Open;
		
		/** Active when the count of the collection is less than the provided value. */
		public int LessThan
		{
			get { return _compare.Y; }
			set
			{
				_compare.Y = value;
				_high = Range.Exclusive;
				UpdateState();
			}
		}

		/** Active when the count of the collection is less than or equal to the provided value. */
		public int LessThanEqual
		{
			get { return _compare.Y; }
			set
			{
				_compare.Y = value;
				_high = Range.Inclusive;
				UpdateState();
			}
		}
		
		/** Active when the count of the collection is greater than the provided value. */
		public int GreaterThan
		{
			get { return _compare.X; }
			set
			{
				_compare.X = value;
				_low = Range.Exclusive;
				UpdateState();
			}
		}

		/** Active when the count of the collection is greater than the provided value. */
		public int GreaterThanEqual
		{
			get { return _compare.X; }
			set
			{
				_compare.X = value;
				_low = Range.Inclusive;
				UpdateState();
			}
		}
		
		/** Active when the count of the collection is equal to the provided value. */
		public int EqualTo
		{
			get { return _compare.X; }
			set
			{
				_compare.X = _compare.Y = value;
				_low = Range.Inclusive;
				_high = Range.Inclusive;
				UpdateState();
			}
		}

		IDisposable _subscription;

		void IObserver.OnSet(object newValue)
		{
			Assess(1);
		}
		void IObserver.OnFailed(string message)
		{
			Assess(0);
		}
		void IObserver.OnAdd(object addedValue)
		{
			Assess(_oldCount+1);
		}
		void IObserver.OnRemoveAt(int index)
		{
			Assess(_oldCount-1);
		}

		void IObserver.OnNewAt(int index, object value)
		{
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			Assess(_oldCount + 1);
		}

		void IObserver.OnClear()
		{
			Assess(0);
		}

		void IObserver.OnNewAll(IArray values)
		{
			Assess(values.Length);
		}
		
		internal bool TestIsClean
		{
			get { return _subscription == null; }
		}
	}
}
