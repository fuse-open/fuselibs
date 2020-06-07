using Uno;
using Uno.Compiler;
using Uno.Testing;
using Uno.UX;

using FuseTest;

using Fuse.Elements;

namespace Fuse.Navigation.Test
{
	public class RouteTest : TestBase
	{
		[Test]
		public void Serialize1()
		{
			var route = new Route("page", "{}");
			var json = Route.Serialize(route);
			Assert.AreEqual("{\"path\":\"page\",\"parameter\":{},\"subroute\":null}", json);
		}

		[Test]
		public void Serialize2()
		{
			var route = new Route("page", "{}", new Route("subpage"));
			var json = Route.Serialize(route);
			Assert.AreEqual("{\"path\":\"page\",\"parameter\":{},\"subroute\":{\"path\":\"subpage\",\"parameter\":null,\"subroute\":null}}", json);
		}

		[Test]
		public void Serialize3()
		{
			var route = new Route("page", "{}", new Route("multi\nline"));
			var json = Route.Serialize(route);
			Assert.AreEqual("{\"path\":\"page\",\"parameter\":{},\"subroute\":{\"path\":\"multi\\nline\",\"parameter\":null,\"subroute\":null}}", json);
		}

		[Test]
		public void Deserialize1()
		{
			var deserialized = Route.Deserialize("{\"path\":\"page\",\"parameter\":{\"test\":1},\"subroute\":null}");
			var route = new Route("page", "{\"test\":1}");
			Assert.AreEqual(route.Path, deserialized.Path);
			Assert.AreEqual(route.Parameter, deserialized.Parameter);
			Assert.AreEqual(route.SubRoute, deserialized.SubRoute);
		}

		[Test]
		public void Deserialize2()
		{
			var deserialized = Route.Deserialize("{\"path\":\"page\",\"parameter\":[1,2,3],\"subroute\":null}");
			var route = new Route("page", "[1,2,3]");
			Assert.AreEqual(route.Path, deserialized.Path);
			Assert.AreEqual(route.Parameter, deserialized.Parameter);
			Assert.AreEqual(route.SubRoute, deserialized.SubRoute);
		}

		[Test]
		public void Deserialize3()
		{
			var parameter = "{\"path\":\"page\",\"parameter\":[1,2,3],\"subroute\":null}";
			var deserialized = Route.Deserialize("{\"path\":\"page\",\"parameter\":" + parameter + ",\"subroute\":null}");
			var route = new Route("page", parameter);
			Assert.AreEqual(route.Path, deserialized.Path);
			Assert.AreEqual(route.SubRoute, deserialized.SubRoute);
			var p1 = Route.Deserialize(parameter);
			var p2 = Route.Deserialize(deserialized.Parameter);
			Assert.AreEqual(p1.Path, p2.Path);
			Assert.AreEqual(p1.SubRoute, p2.SubRoute);
			Assert.AreEqual(p1.SubRoute, p2.SubRoute);
		}

		[Test]
		public void DeserializeThenSerialize()
		{
			var route = new Route("page", "{\"test\":50}", new Route("subpage", "{\"test\":60}", new Route("subsubpage")));
			var deserialized = Route.Deserialize(Route.Serialize(route));
			Assert.AreEqual(route.Path, deserialized.Path);
			Assert.AreEqual(route.Parameter, deserialized.Parameter);
			var s1 = Route.Serialize(route.SubRoute);
			var s2 = Route.Serialize(deserialized.SubRoute);
			Assert.AreEqual(s1, s2);
		}

	}
}
