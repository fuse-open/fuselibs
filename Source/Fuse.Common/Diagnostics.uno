using Uno;
using Uno.Compiler;
using Uno.Collections;

namespace Fuse
{
	public enum DiagnosticType
	{
		UserSuccess,
		UserError,
		UserWarning,
		InternalError,
		Deprecated,
		Unsupported,
		PerformanceWarning,
	}
	
	/** @hide */
	public interface ISourceLocation
	{
		int SourceLineNumber { get; }
		string SourceFileName { get; }
		/* Return the nearest ISourceLocation that is known. This should walk up the tree of nodes until a UX source node is found. */
		ISourceLocation SourceNearest { get; }
	}
	
	/**
		Assume that any of these properties can be null (except Type).
	*/
	public class Diagnostic
	{
		public readonly DiagnosticType Type;
		public readonly string Message;
		public readonly object SourceObject;
		public readonly string FilePath;
		public readonly int LineNumber;
		public readonly string MemberName;
		public readonly Exception Exception;
		
		//The "Near" information is the most recent known position in the user's code (UX) where the 
		//diagnostics originates. It maybe null.
		public readonly object NearObject;
		public readonly object NearLineNumber;
		public readonly object NearFileName;

		internal bool IsTemporalWarning;
		
		internal Uno.Diagnostics.DebugMessageType UnoType
		{
			get
			{
				switch (Type)
				{
					case DiagnosticType.UserSuccess:
						return Uno.Diagnostics.DebugMessageType.Information;

					case DiagnosticType.UserWarning:
					case DiagnosticType.Deprecated:
					case DiagnosticType.Unsupported:
					case DiagnosticType.PerformanceWarning:
						return Uno.Diagnostics.DebugMessageType.Warning;

					case DiagnosticType.UserError:
					case DiagnosticType.InternalError:
						return Uno.Diagnostics.DebugMessageType.Error;

					default:
						throw new Exception("invalid Type: " + Type);
				}
			}
		}

		public Diagnostic(DiagnosticType type, string message, object sourceObject, string filePath, int lineNumber, string memberName, Exception exception = null)
		{
			Type = type;
			Message = message;
			SourceObject = sourceObject;
			FilePath = filePath;
			LineNumber = lineNumber;
			MemberName = memberName;
			//diagnostics only care about the source exception
			Exception = WrapException.Unwrap(exception);

			// capture Near information at creation in case it changes (like unrooting) prior to being displayed
			var sl = SourceObject as ISourceLocation;
			if (sl != null)
				sl = sl.SourceNearest;
			if (sl != null)
			{
				NearObject = sl;
				NearLineNumber = sl.SourceLineNumber;
				NearFileName = sl.SourceFileName;
			}
		}

		public override string ToString()
		{
			return Format(true);
		}
		
		internal string Format( bool withType )
		{
			var msg = string.Empty;

			if (withType)
			{
				//use "friendlier" output for some types
				switch (Type)
				{
					case DiagnosticType.UserSuccess: msg += "Success"; break;
					case DiagnosticType.UserError: msg += "Error"; break;
					case DiagnosticType.UserWarning: msg += "Warning"; break;
					default: msg += Type; break;
				}
				msg += ": ";
			}

			if (Message != null)
				msg += Message;

			if (Exception != null)
				msg += ": " + Exception.Message;

			if (SourceObject != null)
				msg += "\n\tIn: " + SourceObject;

			if (NearObject != null)
			{
				if (NearObject != SourceObject)
					msg += "\n\tNear: " + NearObject;
				msg += " (" + NearFileName + ":" + NearLineNumber +")";
			}
				
			if defined(DEBUG)
			{
				if (FilePath != null)
					msg += "\n\tFuse: " + FilePath + ":" + LineNumber;
			}

			return msg;
		}
	}

	[Obsolete]
	public interface IScriptException
	{
		string FileName { get; }
		int LineNumber { get; }
	}
	
	public delegate void DiagnosticHandler( Diagnostic d );
	
	/** 
		Static API for reporting diagnostic warnings and errors for display in visual tools 
	
		The `User...` messages indicate the user (programmer) has done something wrong and needs
		to modify their code. These will most likely be displayed prominantly to the user. This should be seen
		from the point of view of a typical UX/JS user, not somebody writing Uno code.
		
		The `Internal...` messages are for situations that can't be directly attributed to a user error. They
		are an indication of a fuselibs error, or a Uno programmer error.
		
		The `Unknown...` messages are for errors coming from the native platform or in places
		where the cause of the error really isn't known, but probably isn't a user or internal programming
		error.
		
		The `object` of the error messages should be the object which is generating the error; the Node
		which it would most likely be associated with in the UX tree. This is typically `this` in instance
		contexts.
	*/
	public static class Diagnostics
	{
		public static event DiagnosticHandler DiagnosticReported;
		public static event DiagnosticHandler DiagnosticDismissed;

		static void Dismiss(Diagnostic d) 
		{
			if (DiagnosticDismissed != null)
				DiagnosticDismissed(d);
		}
		
		public static void Report(Diagnostic d)
		{
			// Diagnostics can be generated at any point, during various update phases, and in other threads,
			// this is something people handling DiagnosticReported needs to care about.
			if (DiagnosticReported != null)
				DiagnosticReported(d);
			else
				Uno.Diagnostics.Debug.Log(d.Format(false), d.UnoType);
		}

		class Temporal: IDisposable
		{
			readonly Diagnostic _diag;
			public Temporal(Diagnostic diag)
			{
				_diag = diag;
			}

			public void Dispose()
			{
				Dismiss(_diag);
			}
		}

		/** Reports a temporary diagnostic condition. 
		
			The error is also sent to debug_log. If this is not desired, use `ReportTemporalWarning`.

			The condition is valid until `.Dispose()` is called on the returned object.
		*/
		public static IDisposable ReportTemporal(Diagnostic d)
		{
			if (DiagnosticReported != null)
				DiagnosticReported(d);

			Uno.Diagnostics.Debug.Log(d.ToString(), d.UnoType);

			return new Temporal(d);
		}

		/** Reports a temporary diagnostic condition that should not be printed to debug_log.
			The condition is valid until `.Dispose()` is called on the returned object.
		*/
		public static IDisposable ReportTemporalWarning(Diagnostic d)
		{
			d.IsTemporalWarning = true;

			if (DiagnosticReported != null)
				DiagnosticReported(d);

			return new Temporal(d);
		}

		public static IDisposable ReportTemporalUserWarning(string message, object origin)
		{
			return ReportTemporalWarning(new Diagnostic(DiagnosticType.UserWarning, message, origin, null, 0, null, null));
		}

		/**
			An error that has most likely been caused by a high-level programming mistake, such
			as a property mismatch, unsupported enum, or other UX setup error.
		*/
		public static void UserError(string msg, object obj,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "", Exception e = null)
		{
			Report(new Diagnostic(DiagnosticType.UserError, msg, obj, filePath, lineNumber, memberName, e));
		}
		
		/**
			In some situations it's possible to detect that the user has resolved an error. This function
			can report such things.
		*/
		public static void UserSuccess(string msg, object obj,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "" )
		{
			Report(new Diagnostic(DiagnosticType.UserSuccess, msg, obj, filePath, lineNumber, memberName));
		}
		
		/**
			Get the UX level name of the object's type.
			
			This just drops the namespace name for now.
		*/
		static string UserTypeOf( object a )
		{
			var q = "" + a;
			var e = q.LastIndexOf('.');
			if (e == -1)
				e = 0;
			else
				e = e +1;
			return q.Substring(e);
		}
		
		/**
			A node was rooted in a place where it should not have been. This is a common enough scenario
			to warrant custom handling for consistency.
		*/
		public static void UserRootError( string expectedType, object actualParent, object obj,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "")
		{
			UserError( UserTypeOf(obj) + " cannot be used in a " + UserTypeOf(actualParent) + "." +
				" A " + expectedType + " parent is expected", obj, filePath, lineNumber, memberName );
		}
		
		/**
			An error that is most likely not a direct result of the user (programmer) doing something incorrectly
			but is an internal fuselibs error.
		*/
		public static void InternalError(string msg, object obj = null, 
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "" )
		{
			Report(new Diagnostic(DiagnosticType.InternalError, msg, obj, filePath, lineNumber, memberName));
		}
		
		/**
			Used when an expected exception is caught and otherwise ignored (processing continues).
			Internal implies the immediate cause is not known and it cannot be attributed to a user error.
		*/
		public static void UnknownException(string msg, Exception ex, object obj, 
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "" )
		{
			Report(new Diagnostic(DiagnosticType.InternalError, msg, obj, filePath, lineNumber, memberName, ex));
		}
		
		public static void Deprecated(string msg, object obj, 
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "" )
		{
			Report(new Diagnostic(DiagnosticType.Deprecated, msg, obj, filePath, lineNumber, memberName));
		}
		
		public static void Unsupported(string msg, object obj,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "" )
		{
			Report(new Diagnostic(DiagnosticType.Unsupported, msg, obj, filePath, lineNumber, memberName));
		}

		public static void PerformanceWarning(string msg,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0,
			[CallerMemberName] string memberName = "" )
		{
			Report(new Diagnostic(DiagnosticType.PerformanceWarning, msg, null, filePath, lineNumber, memberName));
		}

		/**
			The user is doing something that warrants a warning about use. This should be used for things
			that are almost errors, but the code may still work nonetheless.
			
			This should be used only in rare circumstances. Generally code works without issue, or it has
			been deprecated, or the user has made an error. Use a different reporting function as appropriate.
		*/
		public static void UserWarning(string msg, object obj,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0,
			[CallerMemberName] string memberName = "" )
		{
			Report(new Diagnostic(DiagnosticType.UserWarning, msg, obj, filePath, lineNumber, memberName));
		}
	}
}
