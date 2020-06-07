using Uno;
using Uno.Testing;
using Uno.Collections;

using Fuse.Elements;
using Fuse.Controls;
using Fuse.Layouts;
using FuseTest;

class Issue2462Text : Text
{
	protected override void OnUnrooted()
	{
		((Grid)Parent).ColumnCount = 0;
		Value = "bar";
		base.OnUnrooted();
	}
}

namespace Fuse.Controls.Test
{

	public class GridTest : TestBase
	{
		private class GridDummyElement : Element
		{
			protected override void OnDraw(Fuse.DrawContext dc) { }
 		}

		[Test]
		public void AllElementProps()
		{
			var g = new Grid();
			ElementPropertyTester.All(g);
		}

		[Test]
		public void AllElementLayoutTest()
		{
			var g = new Grid();
			ElementLayoutTester.All(g);
		}

		[Test]
		public void AllPanelProps()
		{
			var s = new Panel();
			s.Layout = new GridLayout();
			PanelTester.AllSimpleTests(s);
		}

		[Test]
		public void AllPanelLayoutTets()
		{
			var s = new Panel();
			s.Layout = new GridLayout();
			PanelTester.AllLayoutTests(s);
		}

		[Test]
		public void SetRowTest()
		{
			var e = new GridDummyElement();
			Grid.SetRow(e, 2);
			Assert.AreEqual(2, Grid.GetRow(e));
		}

		[Test]
		public void SetColumnTest()
		{
			var e = new GridDummyElement();
			Grid.SetColumn(e, 10);
			Assert.AreEqual(10, Grid.GetColumn(e));
		}

		[Test]
		public void ResetRowTest()
		{
			var e = new GridDummyElement();
			var row = Grid.GetRow(e);
			Grid.SetRow(e, 10);
			Assert.AreEqual(10, Grid.GetRow(e));
			Grid.ResetRow(e);
			Assert.AreEqual(row, Grid.GetRow(e));
		}

		[Test]
		public void ResetColumnTest()
		{
			var e = new GridDummyElement();
			var column = Grid.GetColumn(e);
			Grid.SetColumn(e, 10);
			Assert.AreEqual(10, Grid.GetColumn(e));
			Grid.ResetColumn(e);
			Assert.AreEqual(column, Grid.GetColumn(e));
		}

		[Test]
		public void RowColumnTest()
		{
			var g = new Grid();
			var c1 = new Column();
			var c2 = new Column();
			var r1 = new Row();
			var r2 = new Row();
			g.RowList.Add(r1); g.RowList.Add(r2);
			g.ColumnList.Add(c1); g.ColumnList.Add(c2);
			Assert.AreEqual(2, g.RowList.Count);
			Assert.AreEqual(2, g.ColumnList.Count);
		}

		[Test]
		public void AutoCellBindingLayoutTest()
		{
			using (var root = new TestRootPanel(true))
			{
				var parent = new Grid();
				root.Children.Add(parent);
				var r1 = new Row();
				var r2 = new Row();
				var c1 = new Column() { Width = 2 };
				var c2 = new Column();
				parent.RowList.Add(r1); parent.RowList.Add(r2);
				parent.ColumnList.Add(c1); parent.ColumnList.Add(c2);

				var p1 = new Panel() { Width = 843, SnapToPixels = false };
				var p2 = new Panel();
				Grid.SetColumn(p2, 1);
				var p3 = new Panel();

				parent.Children.Add(p1);
				parent.Children.Add(p2);
				parent.Children.Add(p3);

				root.Layout(int2(1025, 925));
				LayoutTestHelper.TestElementLayout(p1, float2(843, 925/2f), float2((1025*2/3f)/2-843/2f, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(p2, float2(1025/3f, 925/2f), float2(1025*2/3f, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(p3, float2(1025*2/3f, 925/2f), float2(0, 925/2f), 0.0001f);
			}
		}

		[Test]
		public void ProportionColumnsTest()
		{
			using (var root = new TestRootPanel())
			{
				var parent = new Grid()
				{
					Width = 473
				};
				parent.Columns = "1*, 3*, 8*";
				parent.Rows = "57, 57, 57";
				root.Children.Add(parent);

				var child1 = CreateCell(parent, 0, 0);
				var child2 = CreateCell(parent, 0, 1);
				var child3 = CreateCell(parent, 0, 2);
				/*var child4 =*/ CreateCell(parent, 1, 1);

				LayoutTestHelper.TestElementLayout(root, child1, int2(800, 400), float2(473 / 12f, 57), float2(0, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child2, int2(800, 400), float2(473 * 3 / 12f, 57), float2(473 / 12f, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child3, int2(800, 400), float2(473 * 8 / 12f, 57), float2(473 * 4 / 12f, 0), 0.0001f);
			}
		}

		[Test]
		public void ProportionRowsTest()
		{
			using (var root = new TestRootPanel(true))
			{
				var parent = new Grid()
				{
					Height = 890
				};
				parent.Rows = "3*, 5*, 8*";
				parent.Columns = "57";
				root.Children.Add(parent);

				var child1 = CreateCell(parent, 0, 0);
				var child2 = CreateCell(parent, 1, 0);
				var child3 = CreateCell(parent, 2, 0);

				LayoutTestHelper.TestElementLayout(root, child1, int2(800, 400), float2(57, 890 * 3 /  16f), float2(0, 0));
				LayoutTestHelper.TestElementLayout(root, child2, int2(800, 400), float2(57, 890 * 5 /  16f), float2(0, 890 * 3 /  16f));
				LayoutTestHelper.TestElementLayout(root, child3, int2(800, 400), float2(57, 890 * 8 /  16f), float2(0, 890 * 8 /  16f));
			}
		}

		[Test]
		public void AbsoluteRowsTest()
		{
			using (var root = new TestRootPanel())
			{
				var parent = new Grid();
				root.Children.Add(parent);
				parent.Rows = "210, 607, 318";
				parent.Columns = "1*, 1*, 1*";

				var child1 = CreateCell(parent, 0, 2);
				var child2 = CreateCell(parent, 1, 1);
				var child3 = CreateCell(parent, 2, 0);

				LayoutTestHelper.TestElementLayout(root, child1, int2(1182, 1327), float2(1182/3f, 210), float2(1182 * 2/3f, 0));
				LayoutTestHelper.TestElementLayout(root, child2, int2(1182, 1327), float2(1182/3f, 607), float2(1182/3f, 210));
				LayoutTestHelper.TestElementLayout(root, child3, int2(1182, 1327), float2(1182/3f, 318), float2(0, 210 + 607));
			}
		}

		[Test]
		public void AbsoluteColumnsTest()
		{
			using (var root = new TestRootPanel())
			{
				var parent = new Grid();
				root.Children.Add(parent);
				parent.Columns = "336, 375, 467";
				parent.Rows = "1*, 1*, 1*";

				var child1 = CreateCell(parent, 0, 2);
				var child2 = CreateCell(parent, 1, 1);
				var child3 = CreateCell(parent, 2, 0);

				LayoutTestHelper.TestElementLayout(root, child1, int2(1844, 1645), float2(467, 1645/3f), float2(336 + 375, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child2, int2(1844, 1645), float2(375, 1645/3f), float2(336, 1645/3f), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child3, int2(1844, 1645), float2(336, 1645/3f), float2(0, 1645 * 2/3f), 0.0001f);
			}
		}

		[Test]
		public void AutoRowsTest()
		{
			using (var root = new TestRootPanel(true))
			{
				var parent = new Grid();
				root.Children.Add(parent);
				parent.Rows = "auto,107,auto";
				parent.Columns = "1*, 1*, 1*";

				var child1 = CreateCell(parent, 0, 2);
				child1.Height = 125;
				var child2 = CreateCell(parent, 1, 1);
				child2.Height = 109;
				var child3 = CreateCell(parent, 2, 0);
				child3.Height = 824;

				LayoutTestHelper.TestElementLayout(root, child1, int2(1684, 1876), float2(1684/3f, 125), float2(1684 * 2/3f, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child2, int2(1684, 1876), float2(1684/3f, 109), float2(1684/3f, 124), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child3, int2(1684, 1876), float2(1684/3f, 824), float2(0, 125 + 107), 0.0001f);
				Assert.AreEqual(parent.RowList[0].ActualExtent, 125);
				Assert.AreEqual(parent.RowList[1].ActualExtent, 107);
				Assert.AreEqual(parent.RowList[2].ActualExtent, 824);
			}
		}

		[Test]
		public void AutoColumnsTest()
		{
			using (var root = new TestRootPanel())
			{
				var parent = new Grid();
				root.Children.Add(parent);
				parent.Columns = "275,auto,auto";
				parent.Rows = "1*, 1*, 1*";

				var child1 = CreateCell(parent, 0, 2);
				child1.Width = 213;
				var child2 = CreateCell(parent, 1, 1);
				child2.Width = 375;
				var child3 = CreateCell(parent, 2, 0);
				child3.Width = 243;

				LayoutTestHelper.TestElementLayout(root, child1, int2(1498, 1354), float2(213, 1354/3f), float2(275 + 375, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child2, int2(1498, 1354), float2(375, 1354/3f), float2(275, 1354/3f), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child3, int2(1498, 1354), float2(243, 1354/3f), float2((275 - 243)/2f, 1354 * 2/3f), 0.0001f);
				Assert.AreEqual(parent.ColumnList[0].ActualExtent, 275);
				Assert.AreEqual(parent.ColumnList[1].ActualExtent, 375);
				Assert.AreEqual(parent.ColumnList[2].ActualExtent, 213);
			}
		}

		[Test]
		public void ParseDataTest()
		{
			//https://github.com/Outracks/RealtimeStudio/issues/1485
			var c = new List<Column>();
			Column.Parse( " 12 , 1.5 *, auto", c );
			Assert.AreEqual( 3, c.Count );
			Assert.AreEqual( Metric.Absolute, c[0].WidthMetric );
			Assert.AreEqual( 12, c[0].Width );
			Assert.AreEqual( Metric.Proportion, c[1].WidthMetric );
			Assert.AreEqual( 1.5f, c[1].Width );
			Assert.AreEqual( Metric.Auto, c[2].WidthMetric );

			var r = new List<Row>();
			Row.Parse( " 12, 0.275e1* ,auto ", r );
			Assert.AreEqual( 3, r.Count );
			Assert.AreEqual( Metric.Absolute, r[0].HeightMetric );
			Assert.AreEqual( 12, r[0].Height );
			Assert.AreEqual( Metric.Proportion, r[1].HeightMetric );
			Assert.AreEqual( 2.75f, r[1].Height );
			Assert.AreEqual( Metric.Auto, r[2].HeightMetric );
		}

		[Test]
		public void MixedColumnsTest()
		{
			using (var root = new TestRootPanel())
			{
				var parent = new Grid();
				root.Children.Add(parent);
				parent.Columns = "275,2*,auto,5*";
				parent.Rows = "1*, 1*, 1*";

				var child1 = CreateCell(parent, 0, 0);
				var child2 = CreateCell(parent, 1, 1);
				var child3 = CreateCell(parent, 1, 2);
				child3.Width = 217;
				var child4 = CreateCell(parent, 2, 3);

				LayoutTestHelper.TestElementLayout(root, child1, int2(1681, 1354), float2(275, 1354/3f), float2(0, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child2, int2(1681, 1354), float2((1681-275-217)*2/7f, 1354/3f), float2(275, 1354/3f), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child3, int2(1681, 1354), float2(217, 1354/3f), float2(275 + (1681-275-217)*2/7f, 1354/3f), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child4, int2(1681, 1354), float2((1681-275-217)*5/7f, 1354/3f), float2(275 + 217 + (1681-275-217)*2/7f, 1354*2/3f), 0.0001f);
			}
		}

		[Test]
		public void MixedRowsTest()
		{
			using (var root = new TestRootPanel())
			{
				var parent = new Grid();
				root.Children.Add(parent);
				parent.Columns = "1*, 1*, 1*, 1*";
				parent.Rows = "173,auto,5*,3*";

				var child1 = CreateCell(parent, 0, 0);
				var child2 = CreateCell(parent, 1, 1);
				child2.Height = 93;
				var child3 = CreateCell(parent, 2, 2);
				var child4 = CreateCell(parent, 3, 3);

				LayoutTestHelper.TestElementLayout(root, child1, int2(1854, 1153), float2(1854/4f, 173), float2(0, 0), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child2, int2(1854, 1153), float2(1854/4f, 93), float2(1854/4f, 173), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child3, int2(1854, 1153), float2(1854/4f, (1153-93-173)*5/8f), float2(1854*2/4f, 93+173), 0.0001f);
				LayoutTestHelper.TestElementLayout(root, child4, int2(1854, 1153), float2(1854/4f, (1153-93-173)*3/8f), float2(1854*3/4f, 93+173+(1153-93-173)*5/8f), 0.0001f);
			}
		}

		[Test]
		public void AutomaticLayout()
		{
			var grid = new UX.GridAutomaticLayout();
			using (var root = TestRootPanel.CreateWithChild(grid, int2(500,500)))
			{
				//check that state in Grid doesn't affect layout (particularly for spanning items)
				for (int i=0; i < 2; ++i)
				{
					Assert.AreEqual( float2(100,100), grid.C11.ActualPosition );
					Assert.AreEqual( float2(100,200), grid.C21.ActualPosition );
					Assert.AreEqual( float2(300,200), grid.C23.ActualPosition );
					Assert.AreEqual( float2(0,300), grid.C30.ActualPosition );
					Assert.AreEqual( float2(200,400), grid.C42.ActualPosition );

					grid.InvalidateLayout();
					root.StepFrame();
				}
			}
		}

		[Test]
		public void AutomaticLayoutColumnMajor()
		{
			var grid = new UX.GridAutomaticLayoutColumnMajor();
			using (var root = TestRootPanel.CreateWithChild(grid, int2(500,500)))
			{
				//check that state in Grid doesn't affect layout (particularly for spanning items)
				for (int i=0; i < 2; ++i)
				{
					Assert.AreEqual( float2(100,100), grid.C11.ActualPosition );
					Assert.AreEqual( float2(200,100), grid.C21.ActualPosition );
					Assert.AreEqual( float2(200,300), grid.C23.ActualPosition );
					Assert.AreEqual( float2(300,0), grid.C30.ActualPosition );
					Assert.AreEqual( float2(400,200), grid.C42.ActualPosition );

					grid.InvalidateLayout();
					root.StepFrame();
				}
			}
		}

		[Test]
		public void SnapToPixelsLayout()
		{
			using (var root = new TestRootPanel(false, 0.73f))
			{
				var grid = new UX.GridSnapToPixels();
				root.Children.Add(grid);
				var spacing = root.SnapToPixelsSize(grid.CellSpacing);

				var sz = root.SnapToPixelsSize( float2(400) );
				root.Layout(sz);

				Assert.AreEqual(grid.C12.ActualPosition.X + grid.C12.ActualSize.X,
					grid.C21.ActualPosition.X + grid.C21.ActualSize.X);
				Assert.AreEqual(grid.C11.ActualPosition.X + grid.C11.ActualSize.X + spacing,
					grid.C21.ActualPosition.X);
				Assert.AreEqual(grid.C11.ActualPosition.Y + grid.C11.ActualSize.Y + spacing,
					grid.C12.ActualPosition.Y);
				Assert.AreEqual(grid.C42.ActualPosition.Y + grid.C42.ActualSize.Y,
					grid.C33.ActualPosition.Y + grid.C33.ActualSize.Y);
				Assert.AreEqual(grid.C42.ActualPosition.Y + grid.C42.ActualSize.Y + spacing,
					grid.C44.ActualPosition.Y, 1e-4f);

				Assert.AreEqual( sz, grid.C44.ActualPosition + grid.C44.ActualSize,
					1e-4f);
			}
		}

		[Test]
		public void GridContentAlignment()
		{
			using (var root = new TestRootPanel())
			{
				var g = new UX.GridContentAlignment();
				root.Children.Add(g);

				root.Layout(int2(1000));
				Assert.AreEqual(float2(-200,-100), g.A0.ActualPosition);

				Assert.AreEqual(float2(-850,-900), g.B0.ActualPosition);

				Assert.AreEqual(float2(0,0), g.C0.ActualPosition);
			}
		}

		[Test]
		public void Issue1109()
		{
			using (var root = new TestRootPanel())
			{
				var g = new UX.Issue1109s(); //The name UX.Issue1109 was causing a compiler issue?!
				root.Children.Add(g);

				root.Layout(int2(1000));
				//checks evidence of proper support, not the row count directly
				Assert.AreEqual(float2(1000,0),g.G.ActualSize);

				for (int i=0; i < 7; ++i)
					g.G.Children.Add(new Panel() { Height = 100 });
				root.Layout(int2(1000));
				Assert.AreEqual(float2(1000,300),g.G.ActualSize);

				g.G.Children.Remove(g.G.FirstChild<Visual>());
				root.Layout(int2(1000));
				Assert.AreEqual(float2(1000,200),g.G.ActualSize);

				while (g.G.HasVisualChildren)
					g.G.Children.Remove(g.G.FirstChild<Visual>());
				root.Layout(int2(1000));
				Assert.AreEqual(float2(1000,0),g.G.ActualSize);

				//proportional sized
				for (int i=0; i < 7; ++i)
					g.P.Children.Add(new Panel());
				var q = new Panel();
				g.P.Children.Add(q);
				root.Layout(int2(1000));
				Assert.AreEqual(float2(1000,1000),g.P.ActualSize);
				Assert.AreEqual(float2(1000/3.0f),q.ActualSize);

				g.P.Children.Remove(g.P.FirstChild<Visual>());
				g.P.Children.Remove(g.P.FirstChild<Visual>());
				root.Layout(int2(1000));
				Assert.AreEqual(float2(1000,1000),g.P.ActualSize);
				Assert.AreEqual(float2(1000/3.0f,500),q.ActualSize);
			}
		}

		[Test]
		public void Issue2462()
		{
			using (var root = new TestRootPanel())
			{
				var g = new UX.Issue2462();
				root.Children.Add(g);
				root.StepFrame();
				Assert.AreEqual(1, g.Grid.ColumnCount);
				Assert.AreEqual("foo", g.Text.Value);

				root.Children.Remove(g);
				root.StepFrame();
				Assert.AreEqual(0, g.Grid.ColumnCount);
				Assert.AreEqual("bar", g.Text.Value);
			}
		}

		[Test]
		/* this requires the no-auto prefilling of proportions to work, and the first auto measure pass providing
			partial values in GridLayout.Measure */
		public void PreFill()
		{
			var g = new UX.Grid.PreFill();
			using (var root = TestRootPanel.CreateWithChild(g, int2(500,350)))
			{
				//horizontal layout
				Assert.AreEqual(float2(50,100), g.A11.ActualSize);
				Assert.AreEqual(float2(100,100),g.A12.ActualSize);
				Assert.AreEqual(float2(0,100),g.A13.ActualSize);

				Assert.AreEqual(float2(100,50), g.A21.ActualSize);
				Assert.AreEqual(float2(100,50),g.A22.ActualSize);
				Assert.AreEqual(float2(0,50),g.A23.ActualSize);

				Assert.AreEqual(float2(100,200), g.A31.ActualSize);
				Assert.AreEqual(float2(100,200),g.A32.ActualSize);
				Assert.AreEqual(float2(0,200),g.A33.ActualSize);

				//vertical layout
				Assert.AreEqual(float2(150,75), g.B11.ActualSize);
				Assert.AreEqual(float2(50,100), g.B12.ActualSize);
				Assert.AreEqual(float2(300,100), g.B13.ActualSize);

				Assert.AreEqual(float2(150,100), g.B21.ActualSize);
				Assert.AreEqual(float2(50,100), g.B22.ActualSize);
				Assert.AreEqual(float2(300,100), g.B23.ActualSize);

				Assert.AreEqual(float2(150,150), g.B31.ActualSize);
				Assert.AreEqual(float2(50,150), g.B32.ActualSize);
				Assert.AreEqual(float2(300,150), g.B33.ActualSize);
			}
		}

		[Test]
		public void Issue2964()
		{
			var g = new Grid();
			//https://github.com/fusetools/fuselibs-private/issues/2694
			g.Rows = null;
			g.Columns = null;
		}

		[Test]
		//checks that spanning items get correct sizes for non-spanning diretion
		public void GridSpanAuto()
		{
			var p = new UX.Grid.SpanAuto();
			using (var root = TestRootPanel.CreateWithChild(p, int2(200,500)))
			{
				Assert.AreEqual(float2(200,200), p.P1.ActualSize);
				Assert.AreEqual(float2(50,50), p.P2.ActualSize);
				Assert.AreEqual(float2(150,150), p.P3.ActualSize);

				Assert.AreEqual(float2(500,500), p.Q1.ActualSize);
				Assert.AreEqual(float2(100,100), p.Q2.ActualSize);
				Assert.AreEqual(float2(100,100), p.Q3.ActualSize);
				Assert.AreEqual(float2(100,100), p.Q4.ActualSize);
				Assert.AreEqual(float2(200,200), p.Q5.ActualSize);
			}
		}

		[Test]
		//checks that spanning items don't contribute to auto sizes
		public void GridSpanAuto2()
		{
			var p = new UX.Grid.SpanAuto2();
			using (var root = TestRootPanel.CreateWithChild(p, int2(500,200)))
			{
				Assert.AreEqual(float2(50,20), p.P1.ActualSize);
				//Assert.AreEqual(float2(500,20), p.P2.ActualSize);
				Assert.AreEqual(float2(50,20), p.P3.ActualSize);
			}
		}

		[Test]
		//some specific checks of the "default" metric with alignment
		public void GridDefaultMetric()
		{
			var p = new UX.Grid.DefaultMetric();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500,500)))
			{
				Assert.AreEqual(float2(125,300), p.T1.ActualSize);
				Assert.AreEqual(float2(125,300), p.T2.ActualSize);
				Assert.AreEqual(float2(125,300), p.T3.ActualSize);
				Assert.AreEqual(float2(125,300), p.T4.ActualSize);

				Assert.AreEqual(float2(300,125), p.L1.ActualSize);
				Assert.AreEqual(float2(300,125), p.L2.ActualSize);
				Assert.AreEqual(float2(300,125), p.L3.ActualSize);
				Assert.AreEqual(float2(300,125), p.L4.ActualSize);
			}
		}

		[Test]
		public void GridDefaultRow()
		{
			var p = new UX.Grid.DefaultRow();
			using (var dg = new RecordDiagnosticGuard())
			using (var root = TestRootPanel.CreateWithChild(p,int2(300,300)))
			{
				var diagnostics = dg.DequeueAll();
				Assert.AreEqual(1, diagnostics.Count);
				Assert.Contains("incompatible", diagnostics[0].Message);

				//https://github.com/fusetools/fuselibs-private/issues/3286
				//specifically set DefaultRow afterwards to trigger the defect
				p.G1.DefaultRow = "auto";
				root.StepFrame();
				Assert.AreEqual(float2(300,10), p.T1.ActualSize);
				Assert.AreEqual(float2(300,20), p.T2.ActualSize);
				Assert.AreEqual(float2(300,30), p.T3.ActualSize);
			}
		}

		[Test]
		public void GridRowCount()
		{
			var p = new UX.Grid.RowCount();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500,500)))
			{
				Assert.AreEqual(float2(50,500), p.G1.ActualSize);
				Assert.AreEqual(float2(50,100), p.T1.ActualSize);
				Assert.AreEqual(float2(50,100), p.T2.ActualSize);
				Assert.AreEqual(float2(50,100), p.T3.ActualSize);

				Assert.AreEqual(float2(50,500), p.G2.ActualSize);
				Assert.AreEqual(float2(50,100), p.R1.ActualSize);
				Assert.AreEqual(float2(50,100), p.R2.ActualSize);
				Assert.AreEqual(float2(50,100), p.R3.ActualSize);

				Assert.AreEqual(float2(50,100), p.S5.ActualSize);
				Assert.AreEqual(float2(0,400), p.S5.ActualPosition);
				p.G3.Children.Add(p.S2);
				root.IncrementFrame();
				Assert.AreEqual(float2(50,100), p.S2.ActualSize);
				Assert.AreEqual(float2(50,100), p.S5.ActualSize);
				Assert.AreEqual(float2(0,400), p.S5.ActualPosition);
			}
		}

		[Test]
		public void GridColumnCount()
		{
			var p = new UX.Grid.ColumnCount();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500,500)))
			{
				Assert.AreEqual(float2(500,50), p.G1.ActualSize);
				Assert.AreEqual(float2(100,50), p.T1.ActualSize);
				Assert.AreEqual(float2(100,50), p.T2.ActualSize);
				Assert.AreEqual(float2(100,50), p.T3.ActualSize);

				Assert.AreEqual(float2(500,50), p.G2.ActualSize);
				Assert.AreEqual(float2(100,50), p.R1.ActualSize);
				Assert.AreEqual(float2(100,50), p.R2.ActualSize);
				Assert.AreEqual(float2(100,50), p.R3.ActualSize);

				Assert.AreEqual(float2(100,50), p.S5.ActualSize);
				Assert.AreEqual(float2(400,0), p.S5.ActualPosition);
				p.G3.Children.Add(p.S2);
				root.IncrementFrame();
				Assert.AreEqual(float2(100,50), p.S2.ActualSize);
				Assert.AreEqual(float2(100,50), p.S5.ActualSize);
				Assert.AreEqual(float2(400,0), p.S5.ActualPosition);
			}
		}

		[Test]
		public void GridRowCreation()
		{
			var p = new UX.Grid.RowCreation();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000,500)))
			{
				Assert.AreEqual(5,p.G1.RowCount);
				Assert.AreEqual(10,p.G1.ColumnCount);
				Assert.AreEqual(float2(100,100), p.T1.ActualSize);
				Assert.AreEqual(float2(300,100), p.T1.ActualPosition);
				Assert.AreEqual(float2(100,100), p.T4.ActualSize);
				Assert.AreEqual(float2(900,400), p.T4.ActualPosition);

				p.G1.RowCount = 3;
				p.G1.Children.Remove(p.T4);
				root.IncrementFrame();
				Assert.AreEqual(float2(1000/4.0f,500/3.0f), p.T1.ActualSize);
				Assert.AreEqual(float2(3*1000/4.0f,500/3.0f), p.T1.ActualPosition, 1e-4f);
			}
		}

		[Test]
		public void GridListener()
		{
			var p = new UX.Grid.Listener();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500)))
			{
				Assert.AreEqual(float2(10,20),p.P1.ActualSize);
				Assert.AreEqual(float2(20,20),p.P2.ActualSize);
				Assert.AreEqual(float2(10,30),p.P3.ActualSize);
				Assert.AreEqual(float2(20,30),p.P4.ActualSize);

				p.R1.Extent = 10;
				root.IncrementFrame();
				Assert.AreEqual(float2(10,10),p.P1.ActualSize);
				Assert.AreEqual(float2(20,10),p.P2.ActualSize);
				Assert.AreEqual(float2(10,30),p.P3.ActualSize);
				Assert.AreEqual(float2(20,30),p.P4.ActualSize);

				p.G.RowCount = 3;
				p.G.Children.Add(p.P5);
				root.IncrementFrame();
				Assert.AreEqual(float2(10,10),p.P1.ActualSize);
				Assert.AreEqual(float2(20,10),p.P2.ActualSize);
				Assert.AreEqual(float2(10,30),p.P3.ActualSize);
				Assert.AreEqual(float2(20,30),p.P4.ActualSize);
				Assert.AreEqual(float2(10,460),p.P5.ActualSize);

				p.R1.Extent = 50; //should still be an explicit one, with listener
				root.IncrementFrame();
				Assert.AreEqual(float2(10,50),p.P1.ActualSize);
				Assert.AreEqual(float2(20,50),p.P2.ActualSize);
				Assert.AreEqual(float2(10,30),p.P3.ActualSize);
				Assert.AreEqual(float2(20,30),p.P4.ActualSize);
				Assert.AreEqual(float2(10,420),p.P5.ActualSize);
			}
		}

		[Test]
		//ensures that columns added via spanning don't become permanent (this gives a defined
		//behaviour to a layout that was previously undefined)
		public void ColumnOverflow()
		{
			var p = new UX.Grid.ColumnOverflow();
			using (var root = TestRootPanel.CreateWithChild(p,int2(500,400)))
			{
				//relayout causes the issue, not the initial layout
				p.G.InvalidateLayout();
				root.StepFrame();

				Assert.AreEqual(float2(300,100),p.C1.ActualSize);
				Assert.AreEqual(float2(0,100),p.C2.ActualPosition);
				Assert.AreEqual(float2(400,100),p.C3.ActualSize);

				Assert.AreEqual(float2(100,300),p.C6.ActualPosition);
				Assert.AreEqual(float2(0,300),p.C5.ActualPosition);
			}
		}

		[Test]
		public void EmptySpec()
		{
			var p = new UX.Grid.EmptySpec();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100)))
			{
				Assert.AreEqual(float2(100,50),p.P1.ActualSize);
				Assert.AreEqual(float2(100,50),p.P2.ActualSize);
				Assert.AreEqual(float2(0,50),p.P2.ActualPosition);
			}
		}

		[Test]
		public void Issue1019()
		{
			var p = new UX.Grid.Issue1019();
			using (var root = TestRootPanel.CreateWithChild(p,int2(200)))
			{
				Assert.AreEqual( float2(200,150), p.g.ActualSize );
			}

		}

		[Test]
		public void Issue842_1()
		{
			var p = new UX.Grid.Issue842_1();
			using (var root = TestRootPanel.CreateWithChild(p,int2(1000)))
			{
				Assert.AreEqual( float2(100,100), p.t1.ActualSize );
				Assert.AreEqual( float2(100,50), p.t2.ActualSize );
				Assert.AreEqual( float2(100,150), p.g.ActualSize );
				Assert.AreEqual( float2(100,150), p.s.ActualSize );
			}
		}

		[Test]
		public void Issue842_2()
		{
			var p = new UX.Grid.Issue842_2();
			using (var root = TestRootPanel.CreateWithChild(p,int2(100,1000)))
			{
				Assert.AreEqual( float2(100,100), p.t1.ActualSize );
				Assert.AreEqual( float2(100,50), p.t2.ActualSize );
				Assert.AreEqual( float2(100,150), p.g.ActualSize );
				Assert.AreEqual( float2(100,150), p.s.ActualSize );
			}
		}

		//region Private Methods

		private Panel CreateCell(Grid parent, int row, int column)
		{
			var child = new Panel();
			child.SnapToPixels = false;
			parent.SnapToPixels = false;
			Grid.SetColumn(child, column);
			Grid.SetRow(child, row);
			parent.Children.Add(child);
			return child;
		}

		//region Private Methods
	}
}
