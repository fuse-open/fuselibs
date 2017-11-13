using Uno;
using Uno.UX;
using Uno.Testing;

using Fuse;
using Fuse.Scripting;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class JsOrderingTest : TestBase
	{
		[Test]
		public void Basic()
		{
			var p = new UX.JsOrdering.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				//there is no guarantee of initial order, so just reset 
				p.order.ResetAction();
				
				p.Step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "B=2,C=3", p.order.Action );
				
				p.order.ResetAction();
				p.Step2.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "C=4,A=5,B=6", p.order.Action );
			}
		}
		
		[Test]
		public void Function()
		{	
			var p = new UX.JsOrdering.Function();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				root.StepFrameJS();
				p.order.ResetAction();
				
				p.Step1.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "B=1,G=2,A=3", p.order.Action );

				p.order.ResetAction();
				p.Step2.Perform();
				root.StepFrameJS();
				Assert.AreEqual( "G=5,A=6,G=7,B=8", p.order.Action );
			}
		}
	}

}

namespace FuseTest
{
	public class Ordering : Behavior
	{
		string _a;
		public string A
		{
			get { return _a; }
			set
			{
				_a = value;
				AddAction( "A", value );
			}
		}
		
		string _b;
		public string B
		{
			get { return _b; }
			set
			{
				_b = value;
				AddAction( "B", value );
			}
		}
		
		string _c;
		public string C
		{
			get { return _c; }
			set
			{
				_c = value;
				AddAction( "C", value );
			}
		}

		string _action = null;
		public string Action { get { return _action; } }
		
		void AddAction(string name, string value)
		{
			if (_action != null)
				_action += ",";
			_action += name + "=" + value;
		}
	
		public void ResetAction()
		{
			_action = null;
		}
		
		
		static Ordering()
		{
			ScriptClass.Register(typeof(Ordering),
				new ScriptMethod<Ordering>("go", go));
		}
		
		static void go(Ordering o, object[] args)
		{
			o.AddAction( "G", Marshal.ToType<string>(args[0]));
		}
	}
}
