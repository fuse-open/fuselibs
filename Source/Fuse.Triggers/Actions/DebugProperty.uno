using Uno;
using Uno.UX;

namespace Fuse.Triggers.Actions
{
	public interface ITaggedDebugProperty{
		string GetTag();
		string GetStringValue();
	}

	[UXAutoGeneric("DebugProperty", "Value")]
	public sealed class DebugProperty<T> : ITaggedDebugProperty
	{
		public string Tag { get; set; }
		public Property<T> Value { get; set; }

		[UXConstructor]
		public DebugProperty([UXParameter("Value")] Property<T> val)
		{
			Value = val;
		}

		public string GetTag()
		{
			return Tag;
		}

		public string GetStringValue()
		{
			return ""+Value.Get();
		}

		internal string Text{
			get{
				var msg = "";
				if(Tag != null) msg += Tag +" ";
				if(Value != null) msg += Value.Get();
				return msg;
			}
		}
	}

	public sealed class DebugTime : ITaggedDebugProperty
	{
		public string GetTag()
		{
			return "Time";
		}

		public string GetStringValue()
		{
			return ""+Time.FrameTime;
		}
	}

	public sealed class DebugFrame : ITaggedDebugProperty
	{
		public string GetTag()
		{
			return "Frame";
		}

		public string GetStringValue()
		{
			return ""+UpdateManager.FrameIndex;
		}
	}
}
