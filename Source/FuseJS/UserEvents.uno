using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Scripting;

namespace FuseJS
{
	class RaiseEvent
	{
		public Node Source;
		public string Name;
		public Dictionary<string,object> Args;

		//for the update thread
		public void Raise()
		{
			var dispatch = UserEventDispatch.GetByName(Name);
			if (dispatch == null)
			{
				Fuse.Diagnostics.UserError( "Cannot find message with name: " + Name, this);
				return;
			}
			
			//already a shallow call in UpdateManager, so directly raise
			dispatch.DirectRaise(Source, Args);
		}
	}

	[UXGlobalModule]
	public sealed class UserEvents : NativeModule
	{
		static readonly UserEvents _instance;
		public UserEvents()
		{
			if(_instance != null) return; 
			Resource.SetGlobalKey(_instance = this, "FuseJS/UserEvents");
			AddMember(new NativeFunction("raise", Raise));
		}

		static bool _warn;
		
		/**
			args[0] = Name of UserEvent
			args[1] = dictionary of arguments (optional)
		*/
		public static object Raise(Fuse.Scripting.Context context, object[] args)
		{
			if (!_warn)
			{
				//DEPRECATED: 2016-04-25
				Fuse.Diagnostics.Deprecated("The FuseJS/UserEvents `Raise` function is deprecated. Use the `object.raise` on a named event instead.", context);
				_warn = true;
			}
			
			var eventName = (string)args[0];

			//convert arguments, if any
			Dictionary<string,object> postArgs = null;
			Fuse.Scripting.Object p = args.Length > 1 ? args[1] as Fuse.Scripting.Object : null;
			if (p != null)
			{
				var keys = p.Keys;
				postArgs = new Dictionary<string,object>();
				foreach (var key in keys)
					postArgs[key] = p[key];
			}
			
			//must be raised in the Update thread
			var re = new RaiseEvent();
			//we have no way to get our Node at the moment
			//FUSE: https://github.com/fusetools/FuseJS/issues/54
			re.Source = null;
			re.Name = eventName;
			re.Args = postArgs;
			UpdateManager.PostAction(re.Raise);
			return null;
		}
	}
}