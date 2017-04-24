using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse.Animations;

using FuseTest;

namespace Fuse.Triggers.Test
{
	class PulseTestTrigger : Trigger
	{
		public new void Pulse()
		{
			base.Pulse();
		}
	}

	class OpenTestTrigger : Trigger
	{
		public new void DirectActivate() { base.DirectActivate(); }
		public new void DirectDeactivate() { base.DirectDeactivate(); }
		public new void BypassActivate() { base.BypassActivate(); }
		public new void BypassDeactivate() { base.BypassDeactivate(); }
	}

	//mimics a `WhileTrue`
	public class TestWhileTrigger : WhileValue<bool>
	{
		//available in `Timeline`
		public bool StartAtZero
		{
			get { return _startAtZero; }
			set { _startAtZero = value; }
		}

		public new bool Value
		{
			get { return base.Value; }
			set { base.Value = value; }
		}

		protected override bool IsOn { get { return Value; } }
	}

}
