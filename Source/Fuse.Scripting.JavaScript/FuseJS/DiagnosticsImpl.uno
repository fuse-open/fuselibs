using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Reactive.FuseJS
{
	[UXGlobalModule]
	/**
		An internal module providing the Uno callback for the `Diagnostics.js` module.
	*/
	public class DiagnosticsImplModule : NativeModule
	{
		static DiagnosticsImplModule _instance;
		
		public DiagnosticsImplModule()
		{
			if (_instance != null) 
				return;
				
			Uno.UX.Resource.SetGlobalKey(_instance = this, "FuseJS/DiagnosticsImpl");
			
			AddMember(new NativeFunction("report", (NativeCallback)Report));
		}
		
		object Report(Fuse.Scripting.Context context, object[] args)
		{
			if (args.Length != 2)
			{
				Fuse.Diagnostics.InternalError( "Report requires 2 arguments", this);
				return null;
			}
			
			var type = Marshal.ToType<DiagnosticType>(args[0]);
			var msg = Marshal.ToType<string>(args[1]);
			Diagnostics.Report(new Diagnostic(type, msg, null, null, 0, null));
			
			return null;
		}
	}
}