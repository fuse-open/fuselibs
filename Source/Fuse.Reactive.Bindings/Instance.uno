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
				UpdateItems();
			}
		}
		
		void UpdateItems()
		{
			if (IsEnabled)
				SetItems( new object[]{ _item } );
			else
				SetItems( new object[]{} );
		}
		
		bool _isEnabled = true;
		/**
			Provides conditional creation of the desired object.
			
			When `true`, the default, the desired templates will be created. When `false` nothing will be created.
			
			Ensure that when attaching to a binding, or other delayed or async expression, that you force an unknown value to `false`. As the default is `true`, a delayed, or lost value, would otherwise end up being `true` and may temporarily instance the templates.
			
				<Instance IsEnabled="{jsVar} ?? false">
		*/
		public bool IsEnabled
		{
			get { return _isEnabled; }
			set
			{
				if (_isEnabled == value) 
					return;
				_isEnabled = value;
				UpdateItems();
			}
		}
	}
}
