using Uno;
using Uno.Collections;

using Fuse.Scripting;

namespace Fuse
{
	public enum VisualEventMode
	{
		Normal = 0,
		//not sent to disabled visuals
		Enabled = 1,
		//sent to any visual regardless of state
		Force = 2,
	}

	/**
		Cache the List<Visual> since they are used very often in bubbling. A list of lists is required
		since an event can bubble while another one is currently bubling.
	*/
	static class VisualListCache
	{
		static List<List<Visual>> _visualListCache = new List<List<Visual>>();
		
		public static List<Visual> Acquire()
		{
			if (_visualListCache.Count > 0)
			{	
				var l = _visualListCache[_visualListCache.Count-1];
				_visualListCache.RemoveAt(_visualListCache.Count-1);
				return l;
			}
			return new List<Visual>();
		}
		
		public static void Release( List<Visual> list )
		{	
			list.Clear();
			_visualListCache.Add(list);
		}
	}
	
	public abstract class VisualEvent<THandler, TArgs> where TArgs: VisualEventArgs
	{
		PropertyHandle _handle = Properties.CreateHandle();

		public void AddHandler(Visual visual, THandler handler)
		{
			visual.Properties.AddToList(_handle, handler);
		}

		public void RemoveHandler(Visual visual, THandler handler)
		{
			visual.Properties.RemoveFromList(_handle, handler);
		}

		List<THandler> _globalHandlers = new List<THandler>();
		public void AddGlobalHandler(THandler handler)
		{
			_globalHandlers.Add(handler);
		}

		public void RemoveGlobalHandler(THandler handler)
		{
			_globalHandlers.Remove(handler);
		}

		void InvokeGlobalHandlers(Visual visual, TArgs args)
		{
			if (_globalHandlers.Count > 0)
			{
				for (int i = 0; i < _globalHandlers.Count; i++)
					InvokeInternal(_globalHandlers[i], visual, args);
			}
		}

		public void RaiseWithBubble(TArgs args, VisualEventMode type = VisualEventMode.Normal)
		{
			Raise(args,type, true, null);
		}

		internal void RaiseWithBubble(TArgs args, VisualEventMode type,
			Action<TArgs, IList<Visual>> PostBubbleAction)
		{
			Raise(args,type, true, PostBubbleAction);
		}
		
		public void RaiseWithoutBubble(TArgs args, VisualEventMode type = VisualEventMode.Normal)
		{
			Raise(args,type,false, null);
		}

		void Raise(TArgs args, VisualEventMode type, bool bubble,
			Action<TArgs, IList<Visual>> PostBubbleAction = null)
		{
			var visual = ((VisualEventArgs)args).Visual;

			Action<object,object[]> handler = null;
			switch (type)
			{
				case VisualEventMode.Normal: handler = OnRaise; break;
				case VisualEventMode.Force: handler = OnRaise; break;
				case VisualEventMode.Enabled: handler = OnRaiseEnabled; break;
				default:
					debug_log "Invalid RaiseType for event";
					return;
			}

			var list = VisualListCache.Acquire();
			while (visual != null)
			{
				list.Add(visual);
				if (!bubble)
					break;
				visual = visual.Parent;
			}
				
			for (int i=0; i < list.Count; ++i)
				list[i].Properties.ForeachInList(_handle, handler, list[i], args);
			
			if (PostBubbleAction != null)
				PostBubbleAction(args, list);
				
			InvokeGlobalHandlers(visual, args);
			VisualListCache.Release(list);
		}
		
		void OnRaise(object target, object[] args)
		{
			var handler = (THandler)target;
			var visual = (Visual)args[0];
			var eventArgs = (TArgs)args[1];
			InvokeInternal(handler, visual, eventArgs);
		}

		void OnRaiseEnabled(object target, object[] args)
		{
			var handler = (THandler)target;
			var visual = (Visual)args[0];
			var eventArgs = (TArgs)args[1];
			if (visual.IsContextEnabled)
				InvokeInternal(handler, visual, eventArgs);
		}

		void InvokeInternal(THandler handler, object sender, TArgs args)
		{
			try
			{
				Invoke(handler, sender, args);
			}
			catch(Uno.Exception e)
			{
				Fuse.AppBase.OnUnhandledExceptionInternal(e);
			}
		}
		
		protected abstract void Invoke(THandler handler, object sender, TArgs args);
	}


	public class VisualEventArgs : EventArgs, IScriptEvent
	{
		public bool IsHandled { get; set; }

		public Visual Visual { get; private set; }

		public VisualEventArgs(Visual visual)
		{
			if (visual == null)
				throw new ArgumentNullException(nameof(visual));

			Visual = visual;
		}
		
		void IScriptEvent.Serialize(IEventSerializer s) 
		{ 
			Serialize(s);
		}
		
		virtual void Serialize(IEventSerializer s)
		{
		}
	}

	public delegate void VisualEventHandler(object sender, VisualEventArgs args);

	
}
