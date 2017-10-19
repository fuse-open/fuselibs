using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.Threading;
using Uno.IO;
using Uno.UX;

namespace Fuse.Scripting.JavaScript
{
	public abstract class JSContext: Fuse.Scripting.Context, IMirror
	{
		int _reflectionDepth;

		protected JSContext() : base () {}

		public override Fuse.Scripting.IThreadWorker ThreadWorker
		{
			get
			{
				return Fuse.Reactive.JavaScript.Worker;
			}
		}

		internal static JSContext Create()
		{
			if defined(USE_JAVASCRIPTCORE) return new Fuse.Scripting.JavaScriptCore.Context();
			else if defined(USE_V8) return new Fuse.Scripting.V8.Context();
			else if defined(USE_DUKTAPE) return new Fuse.Scripting.Duktape.Context();
			else throw new Exception("No JavaScript VM available for this platform");
		}

		public override object Wrap(object obj)
		{
			return Fuse.Scripting.JavaScript.ThreadWorker.Wrap(obj);
		}

		public override object Unwrap(object obj)
		{
			return ((ThreadWorker)ThreadWorker).Unwrap(obj);
		}

		public object Reflect(object obj)
		{
			var e = obj as Scripting.External;
			if (e != null) return e.Object;

			var sobj = obj as Scripting.Object;
			if (sobj != null)
			{
				if (sobj.ContainsKey("external_object"))
				{
					var ext = sobj["external_object"] as Scripting.External;
					if (ext != null) return ext.Object;
				}
			}

			_reflectionDepth++;
			var res = CreateMirror(obj);
			_reflectionDepth--;

			if (res != null) return res;

			return obj;
		}

		object CreateMirror(object obj)
		{
			if (_reflectionDepth > 50)
			{
				Diagnostics.UserWarning("JavaScript data model contains circular references or is too deep. Some data may not display correctly.", this);
				return null;
			}

			var a = obj as Scripting.Array;
			if (a != null)
			{
				return new ArrayMirror(this, a);
			}

			var f = obj as Scripting.Function;
			if (f != null)
			{
				return new FunctionMirror(f);
			}

			var o = obj as Scripting.Object;
			if (o != null)
			{
				if (o.InstanceOf(Fuse.Scripting.JavaScript.ThreadWorker.FuseJS.Observable))
				{
					return new Observable(((ThreadWorker)ThreadWorker), o, false);
				}
				else if (o.InstanceOf(Fuse.Scripting.JavaScript.ThreadWorker.FuseJS.Date))
				{
					return DateTimeConverterHelpers.ConvertDateToDateTime(o);
				}
				else if (o.InstanceOf(Fuse.Scripting.JavaScript.ThreadWorker.FuseJS.TreeObservable))
				{
					return new TreeObservable(this, o);
				}
				else
				{
					return new ObjectMirror(this, o);
				}
			}

			return null;
		}
	}
}
