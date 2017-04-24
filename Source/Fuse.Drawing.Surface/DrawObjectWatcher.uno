using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Internal;

namespace Fuse.Drawing
{
	interface IDrawObjectWatcherFeedback
	{
		void Changed(object obj);
		void Prepare(object obj);
		void Unprepare(object obj);
	}
	
	/**
		Tracks the modification and preparedness state of draw objects, Stroke and Brush. This
		moves the complexity of this away from the classes that use them.
	*/
	class DrawObjectWatcher : IPropertyListener
	{
		class Item
		{
			public bool Prepared;
			public bool Used;
			public bool Listening;
			public bool Dirty;
			public PropertyObject DrawObject;
		}
		
		MiniList<Item> _items;
		bool _rooted;
		
		public void Sync()
		{
			if (!_rooted)
			{
				Fuse.Diagnostics.InternalError( "Sync while not rooted", this );
				return;
			}
			
			for (int i=_items.Count-1; i >=0; --i)
			{
				var item = _items[i];
				if (item.Used)
				{
					if (!item.Prepared || item.Dirty)
					{
						_feedback.Prepare(item.DrawObject);
						item.Dirty = false;
						item.Prepared = true;
					}
				}
				else
				{
					if (item.Prepared)
					{
						_feedback.Unprepare(item.DrawObject);
						item.Prepared = false;
					}
					
					_items.RemoveAt(i);
				}
			}
		}
		
		IDrawObjectWatcherFeedback _feedback;
		public void OnRooted(IDrawObjectWatcherFeedback feedback)
		{
			_feedback = feedback;
			_rooted = true;
			for (int i=0; i < _items.Count; ++i)
			{
				var item = _items[i];
				item.Dirty = true;
				item.Listening = true;
				item.DrawObject.AddPropertyListener(this);
			}
		}
		
		public void OnUnrooted()
		{
			Reset();
			Sync();
			_rooted = false;
			
			for (int i=0; i < _items.Count; ++i)
			{
				var item = _items[i];
				if (item.Listening)
					item.DrawObject.RemovePropertyListener(this);
			}
			
			_feedback = null;
		}
		
		public void Reset()
		{
			for (int i=0; i < _items.Count; ++i)
			{
				var item = _items[i];
				item.Used = false;
			}
		}
		
		public void Add(Stroke stroke)
		{
			AddObject(stroke);
			AddObject(stroke.Brush);
		}
		
		public void Add(Brush brush)
		{
			AddObject(brush);
		}
		
		void AddObject(PropertyObject drawObject)
		{
			if (drawObject == null)
				return;
				
			for (int i=0; i < _items.Count; ++i)
			{
				if (_items[i].DrawObject == drawObject)
				{
					var item = _items[i];
					item.Used = true;
					return;
				}
			}
			
			if (_rooted)
				drawObject.AddPropertyListener(this);
		
			_items.Add( new Item{
				Used = true,
				DrawObject = drawObject,
				Listening = _rooted,
				Dirty = true });
		}
		
		static Selector ShadingName = "Shading";
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			//Deal with brush directly, see TODO in Stroke
			if (prop == ShadingName)
				return;
				
			for (int i=0; i < _items.Count; ++i)
			{
				var item = _items[i];
				if (item.DrawObject == obj)
				{
					item.Dirty = true;
					break;
				}
			}

			if (_feedback != null) //should never be false
				_feedback.Changed(obj);
		}
	}
}
