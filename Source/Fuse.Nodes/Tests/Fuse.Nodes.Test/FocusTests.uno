using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Input;
using FuseTest;
using Fuse.Controls;

namespace Fuse.Test
{
	public class FocusPrediction : TestBase
	{
		[Test]
		public void PredictFocus1()
		{
			var root = new TestRootPanel();
			var target = new FocusableVisual();
			root.Children.Add(target);

			var result = PredictFocusDown(root);
			Assert.AreEqual(target, result);

		}

		[Test]
		public void PredictFocus2()
		{
			var root = new TestRootPanel();
			var target = new FocusableVisual();

			root.Children.Add(new NoFocus() {
				Children = {
					new NoFocus(),
					target,
				}
			});

			var result = PredictFocusDown(root);
			Assert.AreEqual(target, result);

		}

		[Test]
		public void PredictNextSibling()
		{
			var root = new TestRootPanel();

			var focused = new FocusableVisual();
			var target = new FocusableVisual();

			root.Children.Add(new NoFocus()
			{
				Children =
				{
					focused,
					new NoFocus(),
					target
				}
			});


			var result = PredictFocusDown(focused);
			Assert.AreEqual(target, result);

		}

		[Test]
		public void PredictNextSibling1()
		{
			var root = new TestRootPanel();

			var target = new FocusableVisual();
			var focused = new FocusableVisual()
			{
				Children =
				{
					new NoFocus(),
					new NoFocus(),
					new NoFocus()
					{
						Children = { target }
					},
				}
			};

			root.Children.Add(new NoFocus()
			{
				Children =
				{
					focused,
					new NoFocus(),
				}
			});

			var result = PredictFocusDown(focused);
			Assert.AreEqual(target, result);

		}

		[Test]
		public void PredictPrevSibling1()
		{
			var root = new TestRootPanel();

			var focused = new FocusableVisual();
			var target = new FocusableVisual();

			root.Children.Add(new NoFocus()
			{
				Children =
				{
					target,
					new NoFocus(),
					focused,
				}
			});

			var result = PredictFocusUp(focused);
			Assert.AreEqual(target, result);
		}

		[Test]
		public void PredictNextSibling2()
		{
			var root = new TestRootPanel();

			var focused = new FocusableVisual();
			var target = new FocusableVisual();

			root.Children.Add(new NoFocus()
			{
				Children =
				{
					new FocusableVisual(),
					new NoFocus() { Children = { focused } },
					new NoFocus() { Children = { target } },
					new FocusableVisual(),
				}
			});

			var result = PredictFocusDown(focused);
			Assert.AreEqual(target, result);

		}

		[Test]
		public void PredictPrevSibling2()
		{
			var root = new TestRootPanel();

			var focused = new FocusableVisual();
			var target = new FocusableVisual();

			root.Children.Add(new NoFocus()
			{
				Children =
				{
					new NoFocus()
					{
						Children =
						{
							new FocusableVisual(),
							target,
						}
					},
					new NoFocus()
					{
						Children = { new NoFocus(), new NoFocus(), }
					},
					new NoFocus()
					{
						Children = 
						{
							focused,
							new FocusableVisual()
						}
					}
				}
			});

			var result = PredictFocusUp(focused);
			Assert.AreEqual(target, result);
		}

		class F1 : FocusableVisual { }
		class F2 : FocusableVisual { }
		class F3 : FocusableVisual { }
		class F4 : FocusableVisual { }
		class F5 : FocusableVisual { }
		class F6 : FocusableVisual { }

		[Test]
		public void PredictUpAndDown()
		{
			var root = new TestRootPanel();

			var f1 = new F1();
			var f2 = new F2();
			var f3 = new F3();
			var f4 = new F4();
			var f5 = new F5();
			var f6 = new F6();

			root.Children.Add(new NoFocus()
			{
				f1,
				new NoFocus()
				{
					new NoFocus() { new NoFocus() { f2 } },
					f3,
					new NoFocus() { new NoFocus() { f4, new NoFocus() } },
				},
				f5,
				new NoFocus() { new NoFocus() { new NoFocus() { f6 } } }
			});


			var result = PredictFocusDown(root);
			Assert.AreEqual(f1, result);

			result = PredictFocusDown(result);
			Assert.AreEqual(f2, result);

			result = PredictFocusDown(result);
			Assert.AreEqual(f3, result);

			result = PredictFocusDown(result);
			Assert.AreEqual(f4, result);

			result = PredictFocusDown(result);
			Assert.AreEqual(f5, result);

			result = PredictFocusDown(result);
			Assert.AreEqual(f6, result);

			result = PredictFocusUp(result);
			Assert.AreEqual(f5, result);

			result = PredictFocusUp(result);
			Assert.AreEqual(f4, result);

			result = PredictFocusUp(result);
			Assert.AreEqual(f3, result);

			result = PredictFocusUp(result);
			Assert.AreEqual(f2, result);

			result = PredictFocusUp(result);
			Assert.AreEqual(f1, result);

		}

		static Visual PredictFocusDown(Visual visual)
		{
			return FocusPredictStrategy.Predict(visual, Fuse.Input.FocusNavigationDirection.Down);
		}

		static Visual PredictFocusUp(Visual visual)
		{
			return FocusPredictStrategy.Predict(visual, Fuse.Input.FocusNavigationDirection.Up);
		}
		
		class FocusableVisual : Visual
		{
			public FocusableVisual()
			{
				Focus.SetIsFocusable(this, true);
			}

			public override void Draw(DrawContext dc) {}
		}

		class NoFocus : Visual
		{
			public override void Draw(DrawContext dc) {}
		}

		
		class NotEnabledVisual : FocusableVisual
		{
			public NotEnabledVisual()
			{
				IsEnabled = false;
			}
		}
	}
}
