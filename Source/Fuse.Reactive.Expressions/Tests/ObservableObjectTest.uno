using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using FuseTest;

namespace Fuse.Reactive.Test
{
	class TestData : IObservableObject
	{
		string _foo = "haha";
		string _bar = "hoho";
		TestData _other = null;

		public string Foo { get { return _foo; } set { _foo = value; OnPropertyChanged("Foo", value); } }
		public string Bar { get { return _bar; } set { _bar = value; OnPropertyChanged("Bar", value); } }
		[UXContent]
		public TestData Other { get { return _other; } set { _other = value; OnPropertyChanged("Other", value); } }

		public object this[string key]
		{
			get
			{
				if (key == "Foo") return Foo;
				else if (key == "Bar") return Bar;
				else if (key == "Other") return Other;
				else throw new Exception();
			}
		}

		public string[] Keys
		{
			get { return new [] { "Foo", "Bar", "Other"}; }
		}

		public bool ContainsKey(string key)
		{
			for (var i = 0; i < Keys.Length; i++)
				if (Keys[i] == key) return true;

			return false;
		}

		public void OnPropertyChanged(string key, object value)
		{
			for (var i = 0; i < _listeners.Count; i++)
				_listeners[i].Observer.OnPropertyChanged(_listeners[i], key, value);
		}

		public IPropertySubscription Subscribe(IPropertyObserver observer)
		{
			var sub = new Subscription(this, observer);
			_listeners.Add(sub);
			return sub;
		}

		List<Subscription> _listeners = new List<Subscription>();

		class Subscription: IPropertySubscription
		{
			TestData _td;
			public readonly IPropertyObserver Observer;
			public Subscription(TestData td, IPropertyObserver observer)
			{
				_td = td;
				Observer = observer;
			}
			public bool TrySetExclusive(string propertyName, object newValue)
			{
				throw new Exception();
			}
			public void Dispose()
			{
				_td._listeners.Remove(this);
			}
		}
	}

	class ObservableObjectTest : TestBase
	{
		[Test]
		public void Basics()
		{
			var c = new UX.ObservableObjectTest();
			using (var root = TestRootPanel.CreateWithChild(c))
			{
				root.StepFrame();
				Assert.AreEqual("Hey there haha and hoho and Lol! and yaya!", c.t.Value);
				c.d.Foo = "kjeks";
				Assert.AreEqual("Hey there kjeks and hoho and Lol! and yaya!", c.t.Value);
				c.d.Bar = "kake";
				Assert.AreEqual("Hey there kjeks and kake and Lol! and yaya!", c.t.Value);
				c.td.Foo = "pepperkake";
				Assert.AreEqual("Hey there kjeks and kake and pepperkake and yaya!", c.t.Value);
				c.d.Other = new TestData();
				Assert.AreEqual("Hey there kjeks and kake and haha and hoho!", c.t.Value);
				c.td.Foo = "hest";
				Assert.AreEqual("Hey there kjeks and kake and haha and hoho!", c.t.Value);
			}
		}
	}
}