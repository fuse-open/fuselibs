using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Elements;
using Uno.Testing;
using Fuse.Controls;
using FuseTest;

namespace Fuse.Designer.Test
{
	public class DesignerTest : TestBase
	{

		class VisualAppearedCallback
		{
			public bool Called { get; private set; }

			public void OnVisualAppeared(Rect rect, float4x4 t)
			{
				Called = true;
			}
		}

		[Test]
		public void VisualAppeared()
		{
			var child = new Panel();
			var va = new VisualAppearedCallback();
			UnoHostInterface.OnVisualAppeared(child, va.OnVisualAppeared);
			Assert.IsFalse(va.Called);
			using (var root = new TestRootPanel())
				root.Children.Add(child);
			Assert.IsTrue(va.Called);
		}

		class VisualDisappearedCallback
		{
			public bool Called { get; private set; }

			public void OnVisualDisappeared()
			{
				Called = true;
			}
		}

		[Test]
		public void VisualDisappeared()
		{
			var child = new Panel();

			var vd = new VisualDisappearedCallback();
			UnoHostInterface.OnVisualDisappeared(child, vd.OnVisualDisappeared);

			Assert.IsFalse(vd.Called);

			using (var root = TestRootPanel.CreateWithChild(child))
				root.Children.Remove(child);

			Assert.IsTrue(vd.Called);
		}

		class BoundsChangedCallback
		{
			public Rect Bounds { get; private set; }

			public void OnBoundsChanged(Rect bounds)
			{
				Bounds = bounds;
			}
		}

		[Test]
		public void VisualBoundsChanged()
		{
			var child = new Panel();
			child.Alignment = Alignment.TopLeft;
			using (var root = TestRootPanel.CreateWithChild(child, int2(200)))
			{
				var bc = new BoundsChangedCallback();
				UnoHostInterface.OnVisualBoundsChanged(child, bc.OnBoundsChanged);

				Assert.AreEqual(new Rect(0, 0, 0, 0), bc.Bounds);
				child.Width = 100;
				child.Height = 100;
				root.StepFrame();
				Assert.AreEqual(new Rect(0, 0, 100, 100), bc.Bounds);
			}
		}

		class TransformChanged
		{
			public float3 Translation { get; private set; }

			public float4x4 Transform { get; private set; }

			public void OnTransformChanged(float4x4 t)
			{
				Transform = t;
				float3 scale;
				float4 rotation;
				float3 translation;
				Matrix.Decompose(t, out scale, out rotation, out translation);
				Translation = translation;
			}

		}

		[Test]
		public void VisualTransformChanged()
		{
			var child = new Panel();
			var t = new Translation();
			child.Children.Add(t);

			using (var root = TestRootPanel.CreateWithChild(child, int2(200)))
			{
				var tc = new TransformChanged();
				UnoHostInterface.OnVisualTransformChanged(child, tc.OnTransformChanged);

				Assert.AreEqual(child.WorldTransform, tc.Transform);
				t.X = 50;
				root.StepFrame();
				Assert.AreEqual(50, tc.Translation.X);
			}
		}
	}
}
