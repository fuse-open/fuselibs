using Uno;
using Uno.Collections;
using Uno.Testing;

using Fuse;
using Fuse.Animations;
using Fuse.Controls;
using Fuse.Triggers;

using FuseTest;

namespace AnimationTests.Test
{
	public class AnimationTest
	{
		[Test]
		public void ScaleAnimatorTest_00()
		{
			var panel = new ScaleAnimatorTest_00();

			var forwardStamps = new List<Timestamp>() {
				new Timestamp(0, 1),
				new Timestamp(1.3f, 1),
				new Timestamp(1.4f, 1),
				new Timestamp(0.045f, 3-1, 0.045f/0.17f, 1, Easing.SinusoidalOut, AnimationVariant.Forward),
				new Timestamp(0.125f, 3-1, 0.17f/0.17f, 1, Easing.SinusoidalOut, AnimationVariant.Forward),
				new Timestamp(2.7f, 3),
				new Timestamp(1.4f, 3),
				new Timestamp(8.74f, 3)
			};

			var backwardStamps = new List<Timestamp>() {
				new Timestamp(5.5f, 3),
				new Timestamp(2.0f, 3),
				new Timestamp(0.2f, 3-1, 0.2f/1.3f, 1, Easing.BounceInOut, AnimationVariant.Backward),
				new Timestamp(1.1f, 3-1, 1.3f/1.3f, 1, Easing.BounceInOut, AnimationVariant.Backward),
				new Timestamp(0.8f, 1),
				new Timestamp(3.7f, 1)
			};

			RunGeneralAnimationTest(panel, forwardStamps, backwardStamps, ScaleAnimationAssertion);
		}

		[Test]
		public void RotateAnimatorTest_00()
		{
			var panel = new RotateAnimatorTest_00();

			var forwardStamps = new List<Timestamp>() {
				new Timestamp(0, 231),
				new Timestamp(0.3f, 231),
				new Timestamp(0.45f, 231),
				new Timestamp(0.01f, 231),
				new Timestamp(3.77f, 231),
				new Timestamp(0.14f, 231)
			};

			var backwardStamps = new List<Timestamp>() {
				new Timestamp(0.5f, 0),
				new Timestamp(0.499f, 0),
				new Timestamp(0.001f, 0),
				new Timestamp(0.8f, 0),
				new Timestamp(3.7f, 0)
			};

			RunGeneralAnimationTest(panel, forwardStamps, backwardStamps, RotateAnimationAssertion);
		}

		[Test]
		public void TranslateAnimatorTest_00()
		{
			var panel = new TranslateAnimatorTest_00();

			var forwardStamps = new List<Timestamp>() {
				new Timestamp(0, 0),
				new Timestamp(0.3f, 0),
				new Timestamp(1f, 0),
				new Timestamp(0.7f, 107, 0.7f/2.2f, Easing.CircularIn, AnimationVariant.Forward),
				new Timestamp(1.5f, 107, 2.2f/2.2f, Easing.CircularIn, AnimationVariant.Forward),
			};

			var backwardStamps = new List<Timestamp>() {
				new Timestamp(0.1f, 107),
				new Timestamp(0.3f, 107, 0.3f/2.2f, Easing.CubicInOut, AnimationVariant.Backward),
				new Timestamp(0.7f, 107, 1f/2.2f, Easing.CubicInOut, AnimationVariant.Backward),
				new Timestamp(1.2f, 0),
				new Timestamp(0.8f, 0)
			};

			RunGeneralAnimationTest(panel, forwardStamps, backwardStamps, TranslateAnimationAssertion);
		}

		//region Private Methods

		private void RunGeneralAnimationTest(AnimationTestPanel panel, List<Timestamp> forwardStamps, List<Timestamp> backwardStamps, Action<AnimationTestPanel, Timestamp> assertionAction)
		{
			using (var root = TestRootPanel.CreateWithChild(panel))
			{
				// Forward animation
				panel.Pressed();
				ValidateAnimation(root, panel, forwardStamps, assertionAction);

				// Backward animation
				panel.Unpressed();
				ValidateAnimation(root, panel, backwardStamps, assertionAction);
			}
		}

		private void ValidateAnimation(TestRootPanel root, AnimationTestPanel panel, List<Timestamp> stamps, Action<AnimationTestPanel, Timestamp> assertionAction)
		{
			foreach (var stamp in stamps)
			{
				root.IncrementFrame(stamp.TimeDelta);
				assertionAction(panel, stamp);
			}
		}

		private void ChangeColorAnimationAssertion(AnimationTestPanel animationTestPanel, Timestamp stamp)
		{
			var panel = animationTestPanel as ChangeColorAnimatorTest_00;
			Assert.AreEqual(stamp.ExpectedValue, panel.Color1);
		}

		private void TranslateAnimationAssertion(AnimationTestPanel animationTestPanel, Timestamp stamp)
		{
			var panel = animationTestPanel as TranslateAnimatorTest_00;
			if (panel.Translation1 != null)
			{
				Assert.AreEqual(stamp.ExpectedValue.X, panel.Translation1.X);
			}
		}

		private void RotateAnimationAssertion(AnimationTestPanel animationTestPanel, Timestamp stamp)
		{
			var panel = animationTestPanel as RotateAnimatorTest_00;
			if (panel.Rotation1 != null)
			{
				Assert.AreEqual(stamp.ExpectedValue.X, panel.Rotation1.Degrees);
			}
		}

		private void ScaleAnimationAssertion(AnimationTestPanel animationTestPanel, Timestamp stamp)
		{
			var panel = animationTestPanel as ScaleAnimatorTest_00;
			if (panel.Scaling1 != null)
			{
				Assert.AreEqual(stamp.ExpectedValue.X, panel.Scaling1.Factor);
			}
		}

		private void SimplePressedTriggerAssertion(AnimationTestPanel animationTestPanel, Timestamp stamp)
		{
			var panel = animationTestPanel as SimplePressedTriggerTest_00;
			Assert.AreEqual(stamp.ExpectedValue.X, panel.Translation1.X);
		}

		//endregion
	}
}
