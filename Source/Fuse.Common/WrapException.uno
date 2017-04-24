using Uno;

namespace Fuse
{
	/**
		Wraps an exception that needs to be rethrown at another location. Using this exception indicates
		there isn't an actual new error condition, but the original exception is still the true error.
		
		Locations that report exception information, or forward them for diagnostics, should unwrap
		such exceptions.
	*/
	class WrapException : Exception
	{
		public WrapException( Exception inner )
			: base( "Wrapped Exception", inner )
		{ }

		/**
			Returns the original exception that this one is wrapping (multiple layers may be unwrapped).
		*/
		static public Exception Unwrap(Exception e)
		{
			while (e is WrapException && e.InnerException != null)
			{
				e = e.InnerException;
			}
			
			return e;
		}
		
		public override string ToString()
		{
			return InnerException.ToString();
		}
		
		public override string Message
		{
			get { return InnerException.Message; }
		}
	}
}