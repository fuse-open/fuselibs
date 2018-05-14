using Fuse.Scripting;

namespace Fuse.Charting
{
	public partial class Plot
	{
		static Plot()
		{
			ScriptClass.Register(typeof(Plot),
				new ScriptMethod<Plot>("stepOffset", stepOffset, ExecutionThread.MainThread));
		}
		
		/**
			Steps the `Offset`. The resulting offset will be constrained to always show `Limit` amount of data.
			
			@scriptmethod stepOffset(step)
		*/
		static void stepOffset(Context c, Plot p, object[] args)
		{
			if (args.Length != 1)
			{
				Diagnostics.UserError( "stepOffset requires 1 step argument", p );
				return;
			}
			
			var step = Marshal.ToType<int>(args[0]);
			p._plot.StepOffset(step);
		}
	}
}