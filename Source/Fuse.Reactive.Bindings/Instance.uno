using Uno;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Reactive
{
	/** Creates and inserts an instance of the given template(s).  The templates are only created when the node is rooted.
	
		You may optionally assign an `Item` to the instance, making this function similar to `Each` with a single item.
	*/
	public class Instance: Instantiator
	{
		public Instance() 
		{
			Item = new NoContextItem();
		}

		LinkObserver _subscription;
		
		object _item;
		/**
			A data context for the instantiated item.
			
			This works with features like `MatchKey`, behaving like an `Each` with a single item in it.
			
			For example, you may have part of the UI depend on the type of data being viewed:
			
				<Instance Item="{card}" MatchKey="type">
					<NumericCard ux:Template="number"/>
					<FaceCard ux:Template="face"/>
					<JokerCard ux:Template="joker"/>
				</Instance>
		*/
		public object Item
		{
			get { return _item; }
			set
			{
				if (_item == value)
					return;
		
				if (_subscription != null)
				{
					_subscription.Dispose();
					_subscription = null;
				}
				
				_item = value;
				
				var obs = _item as IObservable;
				if (obs != null)
					_subscription = new LinkObserver(this, obs);
				else
					SetItems( new object[]{ _item } );
			}
		}
		
		//Observable's must be handled by `Instance` since `Each` does not apply template selection to 
		//Observable's stored in the list, only the high-level data type. Ideally it'd be changed there, but
		//that provided to be a much more complicated problem
		class LinkObserver : ValueObserver
		{
			Instance _instance;
			
			public LinkObserver( Instance instance, IObservable data )
			{
				_instance = instance;
				Subscribe(data);
			}
			
			public override void Dispose()
			{
				_instance = null;
				base.Dispose();
			}
			
			protected override void PushData(object newValue)
			{
				if (_instance == null) return;
				_instance.SetItems( new object[]{ newValue} );
			}
			
			protected override void LostData()
			{
				PushData(null);
			}
		}
	}
}
