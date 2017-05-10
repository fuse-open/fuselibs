using System;
using System.Collections.Generic;
using System.Linq;
using Jurassic.Library;
using JR = Jurassic;

namespace Fuse.Scripting.Jurassic
{
	public static class Helpers
	{

		public static T Try<T>(Func<T> operation)
		{
			try
			{
				return operation();
			}
			catch (JR.JavaScriptException jse)
			{
				throw new JurassicException(jse);
			}
		}

		public static void Try(Action operation)
		{
			try
			{
				operation();
			}
			catch (JR.JavaScriptException jse)
			{
				JR.Library.ErrorInstance a = null;
				throw new JurassicException(jse);
			}
		}

		public static object[] FromHandles(object[] handles)
		{
			return handles.Select(FromHandle).ToArray();
		}

		public static object[] ToHandles(object[] values)
		{
			return values.Select(ToHandle).ToArray();
		}

		public static object FromHandle(object value)
		{
			if (value == null)
				return null;

			if (value is double) return value;
			if (value is int) return (double)(int)value;
			if (value is uint) return (double)(uint)value;
			if (value is string) return value;
			if (value is bool) return value;

			if (value is ObjectHandle)
				return ((ObjectHandle)value).ObjectInstance;

			if (value is FunctionHandle)
				return ((FunctionHandle)value).FunctionInstance;

			if (value is ArrayHandle)
				return ((ArrayHandle)value).ArrayInstance;

			throw new Exception("Unsupported type: " + value.GetType());
		}

		public static object ToHandle(object value)
		{
			if (value == null)
				return null;

			if (value is JR.Undefined)
				return null;

			if (value is JR.Null)
				return null;

			if (value is JR.ConcatenatedString)
				return ((JR.ConcatenatedString)value).ToString();

			if (value is ArrayInstance)
				return new ArrayHandle((ArrayInstance)value);

			if (value is FunctionInstance)
				return new FunctionHandle((FunctionInstance)value);

			if (value is ObjectInstance)
				return new ObjectHandle((ObjectInstance)value);

			return value;
		}

	}
}