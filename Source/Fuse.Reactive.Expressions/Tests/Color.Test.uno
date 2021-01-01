using Uno;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	public class ColorTest : TestBase
	{
		[Test]
		//reference values calculated from http://www.easyrgb.com/en/convert.php
		//and https://www.rapidtables.com/convert/color/hsl-to-rgb.html
		public void Model()
		{
			Assert.AreEqual( float4(0.00000f, 1.00000f, 0.39216f, 1),
				ColorModel.RgbaToHsla( float4(200.0f/255,0,0,1) ), 1e-4f );
			Assert.AreEqual( float4(0.30065f, 1.00000f, 0.50000f, 0.5f),
				ColorModel.RgbaToHsla( float4(50.0f/255,255.0f/255,0,0.5f) ), 1e-4f );
			Assert.AreEqual( float4(0.75000f, 1.00001f, 0.19608f, 0.1f),
				ColorModel.RgbaToHsla( float4(50.0f/255,0.0f/255,100.0f/255,0.1f) ), 1e-4f );
			Assert.AreEqual( float4(0.66667f,  0.20000f, 0.24510f, 0.9f),
				ColorModel.RgbaToHsla( float4(50.0f/255,50.0f/255,75.0f/255,0.9f) ), 1e-4f );

			//source was a bit imprecise, using only whole integer values
			Assert.AreEqual( float4(191/255f,  64/255f, 64/255f, 1),
				ColorModel.HslaToRgba( float4(0.0f/360,0.5f,0.5f,1) ), 1e-2f );
			Assert.AreEqual( float4(79/255f,  56/255f, 250/255f, 1),
				ColorModel.HslaToRgba( float4(247.0f/360,0.95f,0.6f,1) ), 1e-2f );
			Assert.AreEqual( float4(228/255f,  235/255f, 224/255f, 1),
				ColorModel.HslaToRgba( float4(100.0f/360,0.2f,0.9f,1) ), 1e-2f );

			Assert.AreEqual( float4(0.5f, 0.5f, 0.5f, 0.8f),
				ColorModel.HslaToRgba( float4(150.0f/360,0f,0.5f,0.8f) ), 1e-4f );
			Assert.AreEqual( float4(0.4f, 0.4f, 0.4f, 0.5f),
				ColorModel.HslaToRgba( float4(150.0f/360,0.00001f,0.4f,0.5f) ), 1e-4f );
		}

		[Test]
		//basic coverage of color functions. These values were not specifically checked for correctness,
		//but based on a visual inspection of similiar results from a demo app
		public void Basic()
		{
			var p = new UX.Color.Basic();
			using (var root = TestRootPanel.CreateWithChild(p))
			{
				Assert.AreEqual( float4(0.3571f, 0.1428f, 0.1428f, 1), p.f1.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.6428f, 0.2571f, 0.2571f, 1), p.f2.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.4650f, 0.2350f, 0.2350f,1), p.f3.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.5350f, 0.1650f, 0.1650f,1), p.f4.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.5400f, 0.1600f, 0.1600f,1), p.f5.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.4250f, 0.2750f, 0.2750f,1), p.f6.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.8142f, 0.5357f, 0.5357f,1), p.f7.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.4000f, 0.1600f, 0.1600f,1), p.f8.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.2000f, 0.3200f, 0.5000f,1), p.f9.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.4400f, 0.5000f, 0.2000f,1), p.f10.Float4Value, 1e-4f );

				Assert.AreEqual( float4(0.0000f, 0.4285f, 0.3500f,1), p.q1.Float4Value, 1e-4f );
				Assert.AreEqual( float4(0.5f,0.2f,0.2f,1), p.q2.Float4Value, 1e-4f );
			}
		}
	}
}
