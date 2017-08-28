using Fuse;
using Fuse.Elements;
using Fuse.Controls;

using FuseTest;

using Uno;
using Uno.Testing;

namespace Fuse.Test
{
	public class TransformModesTest : TestBase
	{
		[Test]
		public void SizeFactor()
		{
			var tn = new UX.SizeFactorModeTest();
			using (var root = TestRootPanel.CreateWithChild(tn,int2(1000)))
			{
				Assert.AreEqual(float3(4,6,1), tn.S1.RelativeTo.GetScaleVector(tn.S1));
				Assert.AreEqual(float3(2.5f,3.5f,1), tn.S1.RelativeTo.GetScaleVector(tn.S2));
			}
		}
		
		[Test]
		/**
			Ensures changes in size in the RelativeNode are reflected in the scale
		*/
		public void SizeFactorChange()
		{
			var tn = new UX.SizeFactorModeChangeTest();
			using (var root = TestRootPanel.CreateWithChild(tn,int2(1000)))
			{
				Assert.AreEqual(4, tn.B.LocalTransform.M11);
				Assert.AreEqual(6, tn.B.LocalTransform.M22);

				tn.A.Width = 150;
				tn.A.Height = 350;
				root.IncrementFrame();
				Assert.AreEqual(3, tn.B.LocalTransform.M11);
				Assert.AreEqual(7, tn.B.LocalTransform.M22);
			}
		}
		
		[Test]
		public void Offset()
		{
			var tn = new UX.OffsetModeTest();
			using (var root = TestRootPanel.CreateWithChild(tn, int2(1000,500)))
			{
				Assert.AreEqual(float3(-950,-450,0), tn.M1.RelativeTo.GetAbsVector(tn.M1));
				Assert.AreEqual(float3(-475,-225,0), tn.M2.RelativeTo.GetAbsVector(tn.M2));

				Assert.AreEqual(float3(-900,-350,0), tn.M3.RelativeTo.GetAbsVector(tn.M3));
				Assert.AreEqual(float3(-450,-175,0), tn.M4.RelativeTo.GetAbsVector(tn.M4));
			}
		}
		
		[Test]
		/*
			Tests event subscription on Translation to ensure it is updating correctly.
		*/
		public void OffsetModeChange()
		{
			var tn = new UX.OffsetModeChangeTest();
			using (var root = TestRootPanel.CreateWithChild(tn, int2(1000)))
			{
				Assert.AreEqual(-100, tn.C.LocalTransform.M41);
				Assert.AreEqual(-50, tn.C.LocalTransform.M42);

				//LocalTransform includes X,Y so we end up with the same values here
				tn.C.X = 10;
				tn.C.Y = 20;
				root.IncrementFrame();
				Assert.AreEqual(-100, tn.C.LocalTransform.M41);
				Assert.AreEqual(-50, tn.C.LocalTransform.M42);

				//
				tn.A.X = 10;
				tn.A.Y = 20;
				root.IncrementFrame();
				Assert.AreEqual(-90, tn.C.LocalTransform.M41);
				Assert.AreEqual(-30, tn.C.LocalTransform.M42);

				//
				tn.M1.RelativeNode = tn.B;
				root.IncrementFrame();
				Assert.AreEqual(800, tn.C.LocalTransform.M41);
				Assert.AreEqual(750, tn.C.LocalTransform.M42);

				//
				tn.P.X = 110;
				root.IncrementFrame();
				Assert.AreEqual(790, tn.C.LocalTransform.M41);
				Assert.AreEqual(750, tn.C.LocalTransform.M42);
			}
		}
		
		[Test]
		/*
			Tests event subscription when PositionOffset is used with the same LayoutMaster. It can generate Placed events without reinvalidating the WorldTransform.
			From signup-concept
		*/
		public void OffsetModeChangeLayoutMaster()
		{
			var tn = new UX.OffsetModeChangeLayoutMasterTest();
			using (var root = TestRootPanel.CreateWithChild(tn,int2(1000)))
			{
				var m = tn.whiteRect.LocalTransform;
				Assert.AreEqual(440, m.M41);
				Assert.AreEqual(700, m.M42);

				tn.signupButton.Margin = float4(10);
				root.IncrementFrame();
				m = tn.whiteRect.LocalTransform;
				Assert.AreEqual(440, m.M41);
				Assert.AreEqual(710, m.M42);
			}
		}
	}
}
