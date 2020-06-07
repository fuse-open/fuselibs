using Uno;
using Uno.Testing;

using FuseTest;
using Fuse.Controls;

namespace Fuse.Navigation.Test
{
	public class TriggersTest : TestBase
	{
		[Test]
		public void HistoryLinear()
		{
			var p = new UX.LinearHistory();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(1, TriggerProgress(p.TheCanGoBack));
				Assert.AreEqual(0, TriggerProgress(p.TheCanGoForward));

				p.TheNav.Active = p.P2;
				Assert.AreEqual(1, TriggerProgress(p.TheCanGoBack));
				Assert.AreEqual(1, TriggerProgress(p.TheCanGoForward));

				p.TheNav.Active = p.P3;
				Assert.AreEqual(0, TriggerProgress(p.TheCanGoBack));
				Assert.AreEqual(1, TriggerProgress(p.TheCanGoForward));

				p.GoForward1.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(p.P2, p.TheNav.Active);

				p.GoBack1.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(p.P3, p.TheNav.Active);

				//deeper
				p.GoForward2.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(p.P2, p.TheNav.Active);

				p.GoBack2.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(p.P3, p.TheNav.Active);

				//other nav
				p.TheNav.Active = p.P2;
				p.GoForward3.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(p.P2, p.TheNav.Active);

				p.GoBack3.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(p.P2, p.TheNav.Active);

				//context
				p.GoForward4.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(p.P1, p.TheNav.Active);

				p.GoBack4.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(p.P2, p.TheNav.Active);
			}
		}

		[Test]
		public void HistoryBase()
		{
			var p = new UX.BaseHistory();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				p.GoForward1.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(1, p.TheNav.Current);

				p.GoBack1.PulseForward();
				root.IncrementFrame();
				Assert.AreEqual(0, p.TheNav.Current);
			}
		}

		[Test]
		public void Issue2633()
		{
			var p = new UX.Issue2633();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( "One", p.TheText.Value );
				p.Active = p.B;
				root.StepFrame(5); //stabilize animation
				Assert.AreEqual( "Two", p.TheText.Value );
			}
		}

	}

	/**
		Simulates how something like WebView hooks into navigation.
	*/
	public class TestBaseNavigation : Panel, IBaseNavigation
	{
		public int Current = 0;
		public int Max = 3;

		public void GoForward()
		{
			Current++;
		}

		public void GoBack()
		{
			Current--;
		}

		public bool CanGoBack
		{
			get { return Current > 0; }
		}

		public bool CanGoForward
		{
			get { return Current < Max; }
		}

		public event HistoryChangedHandler HistoryChanged;
	}
}
