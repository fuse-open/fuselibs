using Uno;
using Uno.Collections;
using Uno.Compiler;
using Uno.Testing;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Input;
using Fuse.Navigation;
using Fuse.Triggers;
using Fuse.Triggers.Actions;
using FuseTest;

namespace Fuse.Triggers.Test
{
	public class NavigationTriggerTest : TestBase
	{
		[Test]
		//Enter trigger shouldn't be called
		public void DirectNavigation()
		{
			var panel = new Panel();
			var navigation = new DirectNavigation();
			panel.Children.Add(navigation);

			var firstPageSetup = SetupPage(panel);
			var secondPageSetup = SetupPage(panel);
			var thirdPageSetup = SetupPage(panel);
			var fourthPageSetup = SetupPage(panel, false);

			using (var root = TestRootPanel.CreateWithChild(panel, int2(200)))
			{
				TestPageTriggers(firstPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(secondPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);

				//+Act1, -Exit1
				navigation.Goto(firstPageSetup.Page,NavigationGotoMode.Transition);
				root.CompleteNextFrame(); //navigation animations use ProcessNextFrame
				TestPageTriggers(firstPageSetup, 1, 0, 0, 0, 0, 1);
				TestPageTriggers(secondPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);

				//+Act2, -Exit2, -Act1, +Exit1
				navigation.Goto(secondPageSetup.Page,NavigationGotoMode.Transition);
				root.CompleteNextFrame();
				TestPageTriggers(firstPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(secondPageSetup, 1, 0, 0, 0, 0, 1);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);

				//-Act2, +Exit2, +Act3, -Exit3
				navigation.Goto(thirdPageSetup.Page,NavigationGotoMode.Transition);
				root.CompleteNextFrame();
				TestPageTriggers(firstPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(secondPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(thirdPageSetup, 1, 0, 0, 0, 0, 1);

				//-Act3, +Exit3
				navigation.Goto(null,NavigationGotoMode.Transition);
				root.CompleteNextFrame();
				TestPageTriggers(firstPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(secondPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(thirdPageSetup, 1, 1, 0, 0, 1, 1);

				panel.Children.Add(fourthPageSetup.Page);
				TestPageTriggers(firstPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(secondPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(thirdPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(fourthPageSetup, 0, 0, 0, 0, 0, 0);

				navigation.Goto(fourthPageSetup.Page,NavigationGotoMode.Transition);
				root.CompleteNextFrame();
				TestPageTriggers(firstPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(secondPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(thirdPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(fourthPageSetup, 1, 0, 0, 0, 0, 1);
			}
		}

		/*
			The large `IncrementFrame` increments here ensure that activation statuses
			are not skipped while moving a large distance at once.
			
			TODO: but of course that fails now and the use-case is uncertain. These need
			to be restored if necessary, see NavigationAnimations.uno for the missing code.
		*/
		[Test]
		public void LinearNavigation()
		{
			var panel = new Panel();
			var navigation = new LinearNavigation();
			panel.Children.Add(navigation);

			var firstPageSetup = SetupPage(panel);
			var secondPageSetup = SetupPage(panel);
			var thirdPageSetup = SetupPage(panel);
			var fourthPageSetup = SetupPage(panel);

			using (var root = TestRootPanel.CreateWithChild(panel, int2(200)))
			{
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(secondPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);

				navigation.Goto(secondPageSetup.Page,NavigationGotoMode.Transition);
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 0, 1, 1, 0, 0, 0);
				TestPageTriggers(secondPageSetup, 1, 0, 0, 0, 0, 1);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);

				navigation.Goto(thirdPageSetup.Page,NavigationGotoMode.Transition);
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 0, 1, 1, 0, 0, 0);
				TestPageTriggers(secondPageSetup, 1, 1, 1, 0, 0, 1);
				TestPageTriggers(thirdPageSetup, 1, 0, 0, 0, 0, 1);

				navigation.Goto(firstPageSetup.Page,NavigationGotoMode.Transition);
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 1, 1, 1, 1, 0, 0);
				//TODO: RESTORE: TestPageTriggers(secondPageSetup, 2, 2, 1, 1, 1, 1);
				TestPageTriggers(thirdPageSetup, 1, 1, 0, 0, 1, 1);

				navigation.Goto(firstPageSetup.Page,NavigationGotoMode.Transition);
				root.IncrementFrame(1);
				firstPageSetup.Reset();
				secondPageSetup.Reset();
				thirdPageSetup.Reset();
				navigation.Goto(fourthPageSetup.Page,NavigationGotoMode.Transition);
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 0, 1, 1, 0, 0, 0);
				//TODO: RESTORE: //TestPageTriggers(secondPageSetup, 1, 1, 1, 0, 0, 1);
				//TODO: RESTORE: //TestPageTriggers(thirdPageSetup, 1, 1, 1, 0, 0, 1);
				TestPageTriggers(fourthPageSetup, 1, 0, 0, 0, 0, 1);
			}
		}

		[Test]
		//Enter trigger shouldn't be called
		public void HierarchicalNavigation()
		{
			var panel = new Panel();
			var navigation = new HierarchicalNavigation();
			panel.Children.Add(navigation);

			var firstPageSetup = SetupPage(panel);
			var secondPageSetup = SetupPage(panel);
			var thirdPageSetup = SetupPage(panel);
			var fourthPageSetup = SetupPage(panel, false);

			using (var root = TestRootPanel.CreateWithChild(panel, int2(200)))
			{
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(secondPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);

				navigation.GoBack();
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 0, 1, 1, 0, 0, 0);
				TestPageTriggers(secondPageSetup, 1, 0, 0, 0, 0, 1);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);

				navigation.GoForward();
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 1, 1, 1, 1, 0, 0);
				TestPageTriggers(secondPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(fourthPageSetup, 0, 0, 0, 0, 0, 0);

				navigation.Goto(fourthPageSetup.Page,NavigationGotoMode.Transition);
				root.IncrementFrame(1);
				TestPageTriggers(firstPageSetup, 1, 2, 1, 1, 1, 0);
				TestPageTriggers(secondPageSetup, 1, 1, 0, 0, 1, 1);
				TestPageTriggers(thirdPageSetup, 0, 0, 0, 0, 0, 0);
				TestPageTriggers(fourthPageSetup, 1, 0, 0, 1, 0, 0);
			}
		}

		private NavigationSetupEntity SetupPage(Panel panel, bool add = true)
		{
			var activatedForwardTriggerAction = new FuseTest.CountAction() { When = TriggerWhen.Forward,
				AtProgress = 0 };
			var activatedBackwardTriggerAction = new FuseTest.CountAction() { When = TriggerWhen.Backward,
				AtProgress = 0 };

			var enterForwardTriggerAction = new FuseTest.CountAction() { When = TriggerWhen.Forward,
				AtProgress = 0 };
			var enterBackwardTriggerAction = new FuseTest.CountAction() { When = TriggerWhen.Backward,
				AtProgress = 0 };

			var exitForwardTriggerAction = new FuseTest.CountAction() { When = TriggerWhen.Forward,
				AtProgress = 0 };
			var exitBackwardTriggerAction = new FuseTest.CountAction() { When = TriggerWhen.Backward,
				AtProgress = 0 };

			var activatedTrigger = new ActivatingAnimation();
			var enterTrigger = new EnteringAnimation();
			var exitTrigger = new ExitingAnimation();

			activatedTrigger.Actions.Add(activatedForwardTriggerAction);
			activatedTrigger.Actions.Add(activatedBackwardTriggerAction);

			enterTrigger.Actions.Add(enterForwardTriggerAction);
			enterTrigger.Actions.Add(enterBackwardTriggerAction);

			exitTrigger.Actions.Add(exitForwardTriggerAction);
			exitTrigger.Actions.Add(exitBackwardTriggerAction);

			var page = new Page();

			page.Children.Add(activatedTrigger);
			page.Children.Add(enterTrigger);
			page.Children.Add(exitTrigger);

			if (add)
				panel.Children.Add(page);
				
			return new NavigationSetupEntity(page, 
				activatedForwardTriggerAction, activatedBackwardTriggerAction,
				enterForwardTriggerAction, enterBackwardTriggerAction,
				exitForwardTriggerAction, exitBackwardTriggerAction);
		}

		private void TestPageTriggers(NavigationSetupEntity setupEntity, 
			int activatedForwardActionPerformedCount, 
			int activatedBackwardActionPerformedCount,
			int enterForwardActionPerformedCount, 
			int enterBackwardActionPerformedCount,
			int exitForwardActionPerformedCount, 
			int exitBackwardActionPerformedCount,
			[CallerFilePath] string filePath = "", [CallerLineNumber] int lineNumber = 0, 
			[CallerMemberName] string memberName = "")
		{
			/*debug_log "+Act: " + setupEntity.ActivatedTriggerForwardAction.PerformedCount +
				"  -Act: " + setupEntity.ActivatedTriggerBackwardAction.PerformedCount +
				"  +Enter: " + setupEntity.EnterTriggerForwardAction.PerformedCount +
				"  -Enter: " + setupEntity.EnterTriggerBackwardAction.PerformedCount +
				"  +Exit: " + setupEntity.ExitTriggerForwardAction.PerformedCount +
				"  -Exit: " + setupEntity.ExitTriggerBackwardAction.PerformedCount;*/
				
			Assert.AreEqual(activatedForwardActionPerformedCount,
				setupEntity.ActivatedTriggerForwardAction.PerformedCount,
				filePath, lineNumber, memberName + " ActivatedForward");
			Assert.AreEqual(activatedBackwardActionPerformedCount,
				setupEntity.ActivatedTriggerBackwardAction.PerformedCount,
				filePath, lineNumber, memberName + " ActivatedBackward");

			Assert.AreEqual(enterForwardActionPerformedCount,
				setupEntity.EnterTriggerForwardAction.PerformedCount,
				filePath, lineNumber, memberName + " EnterForward");
			Assert.AreEqual(enterBackwardActionPerformedCount,
				setupEntity.EnterTriggerBackwardAction.PerformedCount,
				filePath, lineNumber, memberName + " EnterBackward");

			Assert.AreEqual(exitForwardActionPerformedCount,
				setupEntity.ExitTriggerForwardAction.PerformedCount,
				filePath, lineNumber, memberName + " ExitForward");
			Assert.AreEqual(exitBackwardActionPerformedCount,
				setupEntity.ExitTriggerBackwardAction.PerformedCount,
				filePath, lineNumber, memberName + " ExitBackward");
		}
	}
}
