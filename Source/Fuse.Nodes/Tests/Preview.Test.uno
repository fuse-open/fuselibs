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
				p.st.Value = "store";
				
				var o = root.RootViewport.SavePreviewState();
				Assert.AreEqual( null, root.RootViewport.PreviewState.Current );
				
				root.Children.Remove(p);
				root.StepFrame();
				
				root.RootViewport.RestorePreviewState( o );
				Assert.IsTrue( root.RootViewport.PreviewState.Current.Has( StateTest.StateId ) );
				Assert.IsFalse( root.RootViewport.PreviewState.Current.Has( "none" ) );
				
				p = new UX.Preview.State();
				root.Children.Add(p);
				Assert.AreEqual( "store", p.st.Value );
				
				//the second rooting should not use the state, it was consumed
				root.Children.Remove(p);
				root.StepFrame();
				p = new UX.Preview.State();
				root.Children.Add(p);
				Assert.AreEqual( "init", p.st.Value );
			}
		}
	}
	
	public class StateTest : Behavior, IPreviewStateSaver
	{
		public string Value = "init";
		
		public const string StateId = "StateTest";
		
		void IPreviewStateSaver.Save( PreviewStateData data )
		{
			data.Set( StateId, Value );
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
				{
					var q = cur.Consume( StateId ) as string;
					if (q != null)
						Value = q;
				}
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
