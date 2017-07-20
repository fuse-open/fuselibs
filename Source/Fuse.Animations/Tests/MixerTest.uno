using Uno;
using Uno.Testing;

using Fuse;
using FuseTest;

namespace Fuse.Animations.Test
{
	/*
		Tests focusing on testing the mixer system.
	*/
	public class MixerTest : TestBase
	{
		int GetTransformCount(Visual v)
		{
			if (!v.HasChildren)
				return 0;

			int transformCount = 0;
			foreach (var child in v.Children)
			{
				if (child is Transform)
					transformCount++;
			}

			return transformCount;
		}

		[Test]
		/*
			A TransformAnimator should not have a transform in the Node while it is inactive. This is a white-box assuming the Mixer is using a `Transform` on the panel.

			This assume the inactivity/disable is being called correctly (refer to the Trigger tests for this).
		*/
		public void NoTransform()
		{
			var p = new UX.NoTransform();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, GetTransformCount(p));

				p.W.Value = true;
				root.StepFrame(0.5f);
				Assert.AreEqual(1, GetTransformCount(p));
				var t = p.FirstChild<Transform>() as FastMatrixTransform;
				Assert.AreEqual(50,t.Matrix.Matrix.M41,1e-4); //frame/step variation allowed

				p.W.Value = false;
				root.StepFrame(0.6f);//overkill to ensure we reach the end
				Assert.AreEqual(0, GetTransformCount(p));
			}
		}

		[Test]
		/*
			All transform animators on one element result in a single transform being added.
		*/
		public void OneTransform()
		{
			var p = new UX.OneTransform();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual(0, GetTransformCount(p));
				p.W1.Value = true;
				root.StepFrame();
				p.W2.Value = true;
				root.StepFrame();
				p.W3.Value = true;
				root.StepFrame();
				Assert.AreEqual(1, GetTransformCount(p));
				Assert.AreEqual(0, GetTransformCount(p.S));

				p.W1.Value = false;
				p.W2.Value = false;
				p.W3.Value = false;
				root.StepFrame(0.1f); //stabilize bits
				Assert.AreEqual(0, GetTransformCount(p));
			}
		}
	}
}
