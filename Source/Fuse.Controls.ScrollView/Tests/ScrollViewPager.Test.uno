using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Controls.ScrollViewTest
{
	public class ScrollViewPagerTest : TestBase
	{
		void WaitIdle( TestRootPanel root, ScrollViewPager svp, string where )
		{
			var start = Uno.Diagnostics.Clock.GetSeconds();
			while (true) 
			{
				root.StepFrameJS();
				//-1 since frame index increment happens after all activity
				if (svp.LastActivityFrame < UpdateManager.FrameIndex-1)
					return;
					
				var elapsed = Uno.Diagnostics.Clock.GetSeconds() - start;
				if (elapsed > 1.0) {
					throw new Exception( "Waiting too long for idle: " + where );
				}
			}
		}
		
		[Test]
		//This is only a sanity test. If changes are made to ScrollViewPager/ScrollView manual testing is 
		//required. This will catch things that completely break the functionality
		public void Basic()
		{
			var p = new UX.ScrollViewPager.Basic();
			using (var root = TestRootPanel.CreateWithChild(p, int2(300)))
			{
				p.svp.ReachedEnd += OnReachedEnd;
				p.svp.ReachedStart += OnReachedStart;
				
				WaitIdle(root, p.svp, "init");
				Assert.AreEqual(9, p.theEach.Limit);
				Assert.AreEqual("8,7,6,5,4,3,2,1,0", GetDudZ(p.s));
				
				//first init will have us trigger both of these. Due to all the deferred stuff with bindings 
				//I couldn't see any way to prevent this
				_countReachedEnd = 0;
				_countReachedStart = 0;
				
				p.scroll.Goto(float2(0,300));
				WaitIdle(root, p.svp, "goto 300");
				Assert.AreEqual(9, p.theEach.Limit);
				Assert.AreEqual("8,7,6,5,4,3,2,1,0", GetDudZ(p.s));
				Assert.AreEqual(0, p.theEach.Offset);
				
				Assert.AreEqual(0, _countReachedEnd);
				Assert.AreEqual(0, _countReachedStart);
				
				float jiggleTolerance = 1e-2f;
				int offset = 3;
				for (int i=0; i < 4; ++i, offset +=3 )
				{
					p.scroll.Goto(float2(0,600));
					WaitIdle(root, p.svp, "goto 600 #" + i);
					Assert.AreEqual(9, p.theEach.Limit);
					Assert.AreEqual(offset, p.theEach.Offset);
					if (i ==0) 
						Assert.AreEqual("11,10,9,8,7,6,5,4,3", GetDudZ(p.s));
						
					root.StepFrame(5); //let the ScrollView finish jiggling
					Assert.AreEqual(300, p.scroll.ScrollPosition.Y, jiggleTolerance);
				}
				Assert.AreEqual("20,19,18,17,16,15,14,13,12", GetDudZ(p.s));
				Assert.AreEqual(0, _countReachedEnd);
				Assert.AreEqual(0, _countReachedStart);
				
				//reach the end
				p.scroll.Goto(float2(0,600));
				WaitIdle(root,p.svp, "goto 600-end");
				Assert.AreEqual(9, p.theEach.Limit);
				Assert.AreEqual(12, p.theEach.Offset); //max offset
				
				Assert.AreEqual(1, _countReachedEnd);
				Assert.AreEqual(0, _countReachedStart);
				
				//reach the start
				while( p.scroll.ScrollPosition.Y > 0 )
				{
					p.scroll.Goto(float2(0,0));
					WaitIdle(root,p.svp, "scroll start: " + p.scroll.ScrollPosition.Y);
				}
				Assert.AreEqual("8,7,6,5,4,3,2,1,0", GetDudZ(p.s));
				Assert.AreEqual(0, p.theEach.Offset);
				Assert.AreEqual(1, _countReachedEnd);
				Assert.AreEqual(1, _countReachedStart);
			}
		}

		int _countReachedEnd, _countReachedStart;
		void OnReachedEnd(object s, ScrollViewPagerArgs args)
		{
			_countReachedEnd++;
		}
		
		void OnReachedStart(object s, ScrollViewPagerArgs args)
		{
			_countReachedStart++;
		}
		
		[Test]
		// Accesses _scrollable while unrooting
		//https://github.com/fuse-open/fuselibs/issues/560
		public void Issue560()
		{
			var s = new UX.ScrollViewPager.Issue560();
			using (var root = TestRootPanel.CreateWithChild(s, int2(300)))
			{
				s.scroll.Goto( float2(300) );
				s.Children.Remove( s.scroll );
				root.StepFrame(); //just not failing is good
			}
		}
	}
}
