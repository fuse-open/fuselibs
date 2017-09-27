using Uno;
using Uno.Testing;
using Uno.UX;

using FuseTest;

namespace Fuse.Test
{
	/** Tests for preview integration APIs */
	public class PreviewTest : TestBase
	{
		[Test]
		public void State()
		{
			var p = new UX.Preview.State();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "init", p.st.Value );
				p.st.Value = "okay";
				
				var o = root.RootViewport.PreviewSaveState();
				
				root.Children.Remove(p);
				root.StepFrame();
				
				root.RootViewport.PreviewSetState( o );
				
				p = new UX.Preview.State();
				root.Children.Add(p);
				Assert.AreEqual( "okay", p.st.Value );
			}
		}
	}
	
	public class StateTest : Behavior, IPreviewStateSaver
	{
		public string Value = "init";
		
		const string _id = "StateTest";
		
		void IPreviewStateSaver.Save( PreviewStateData data )
		{
			data.Set( _id, Value );
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();

			var ps = PreviewState.Find(this);
			if (ps != null)
			{
				ps.AddSaver( this );
				var cur = ps.Current;
				if (cur != null)
					Value = cur.Get( _id ) as string;
			}
		}
		
		protected override void OnUnrooted()
		{
			var ps = PreviewState.Find(this);
			if (ps != null)
				ps.RemoveSaver(this);
			base.OnUnrooted();
		}
	}
}
