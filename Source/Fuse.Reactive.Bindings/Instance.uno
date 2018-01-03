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
				_item = value;
				SetItems( new object[]{ _item } );
			}
		}
	}
}
