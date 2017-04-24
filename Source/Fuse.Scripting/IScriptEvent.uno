using Uno.UX;

namespace Fuse.Scripting
{
	public interface IEventSerializer
	{
		void AddString(string key, string value);
		void AddInt(string key, int value);
		void AddDouble(string key, double value);
		void AddBool(string key, bool value);
		void AddObject(string key, object obj);
	}

	/**	Interface for objects that can have a script engine representation */
	public interface IScriptObject
	{
		/** The script representation of this object, if created yet. Can return null. */
		object ScriptObject { get; }

		/** The script context of this object, if associated yet. Can return null */
		Context ScriptContext { get; }

		/** Sets the script representation and context association of this object */
		void SetScriptObject(object obj, Context context);
	}

	public interface IScriptEvent
	{
		void Serialize(IEventSerializer s);
	}

	public class ScriptEventArgs: Uno.EventArgs, IScriptEvent
	{
		static ScriptEventArgs _empty = new ScriptEventArgs();
		public new static ScriptEventArgs Empty { get { return _empty; } }

		public virtual void Serialize(IEventSerializer s)
		{
		}
	}

	public class StringChangedArgs: ValueChangedArgs<string>, IScriptEvent
	{
		public StringChangedArgs(string newValue) : base(newValue) {}

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddString("value", Value);
		}
	}

	public class DoubleChangedArgs: ValueChangedArgs<double>, IScriptEvent
	{
		public DoubleChangedArgs(double value): base(value)
		{
		}

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddDouble("value", Value);
		}
	}

	public class BoolChangedArgs: ValueChangedArgs<bool>, IScriptEvent
	{
		public BoolChangedArgs(bool value): base(value)
		{
		}

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddBool("value", Value);
		}
	}
}