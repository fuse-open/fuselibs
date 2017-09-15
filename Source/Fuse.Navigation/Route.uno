using Uno.Text;
using Uno.Data.Json;

namespace Fuse.Navigation
{
	/** Reporesents a route to be used with @Router.

		This class represents one element in a linked list, that forms a multi-level route path
		with optional parameters for each part of the path. 
		
		The instances are immutable.
	*/
	public sealed class Route
	{
		/** The path of the first part of this route.

			Note that this is not the full path of the route, only the first part
			of a possibly multi-level route. See @SubRoute for the next part of the
			route.
		*/
		public readonly string Path;

		/** The parameter to be supplied to the @Path for this part of the route */
		public readonly string Parameter;

		/** Points to the next @Route object in a linked list of path elements. 
			Can be `null` if this is the last path element in the route. */
		public readonly Route SubRoute;

		//a workaround for now in Router
		internal RouterPage RouterPage;

		public Route(string path, string parameter = null, Route subRoute = null)
		{
			Path = path;
			Parameter = parameter;
			SubRoute = subRoute;
		}

		/** Returns the number of path elements in the @SubRoute chain. */
		public int Length
		{
			get 
			{
				if (SubRoute == null) return 1;
				else return SubRoute.Length + 1;
			}
		}

		/** Returns a new route with the given @SubRoute attached. */
		public Route Append( Route subRoute )
		{
			var sub = SubRoute == null ? subRoute : SubRoute.Append(subRoute);
			return new Route(Path, Parameter, sub);
		}
		
		/**
			Returns a @Route without the last @SubRoute in from this @Route.
			If this @Route has no @SubRoute, this method returns this @Route instance.
			If this @Route has a @SubRoute, this method returns a copy of the Route and
			its @SubRoute, excluding the very last @SubRoute link in the chain.
		*/
		internal Route Up()
		{
			if (SubRoute == null) return this;
			else if (SubRoute.SubRoute == null) return new Route(Path, Parameter, null);
			return new Route(Path, Parameter, SubRoute.Up());
		}
		
		internal bool HasUp
		{
			get { return SubRoute != null; }
		}
		
		internal string Format()
		{
			var q = Path ?? "";
			if (Parameter != null)
				q += "?" + Parameter;
			if (SubRoute != null)
				q += "/" + SubRoute.Format();
			return q;
		}

		internal static string Serialize(Route route)
		{
			var builder = new StringBuilder();
			builder.Append("{");
			builder.Append("\"path\":" + JsonWriter.QuoteString(route.Path) + ",");
			builder.Append("\"parameter\":" + (route.Parameter ?? "null") + ",");
			builder.Append("\"subroute\":" + (route.SubRoute != null ? Serialize(route.SubRoute) : "null"));
			builder.Append("}");
			return builder.ToString();
		}

		internal static Route Deserialize(string json)
		{
			return Deserialize(JsonReader.Parse(json));
		}

		static Route Deserialize(JsonReader route)
		{
			if (route.JsonDataType == JsonDataType.Null)
				return null;

			var path = route["path"].AsString();
			var parameter = ParameterToJson(route["parameter"]);
			var subroute = Deserialize(route["subroute"]);

			return new Route(path, parameter, subroute);
		}

		// Parameter should stay in JSON, JsonReader cannot
		// output JSON so have to do it by hand...
		static string ParameterToJson(JsonReader parameter)
		{
			var builder = new StringBuilder();
			switch(parameter.JsonDataType)
			{
				case JsonDataType.Number:
					builder.Append(parameter.AsNumber().ToString());
					break;

				case JsonDataType.Boolean:
					builder.Append(parameter.AsBool().ToString());
					break;

				case JsonDataType.String:
					builder.Append(JsonWriter.QuoteString(parameter.AsString()));
					break;

				case JsonDataType.Array:
				{
					builder.Append("[");
					for (var i = 0; i < parameter.Count; i++)
					{
						builder.Append(ParameterToJson(parameter[i]));
						if (i < parameter.Count - 1)
							builder.Append(",");
					}
					builder.Append("]");
					break;
				}

				case JsonDataType.Object:
				{
					builder.Append("{");
					for (var i = 0; i < parameter.Count; i++)
					{
						var key = parameter.Keys[i];
						builder.Append("\"" + key + "\":");
						builder.Append(ParameterToJson(parameter[key]));
						if (i < parameter.Count - 1)
							builder.Append(",");
					}
					builder.Append("}");
					break;
				}

				case JsonDataType.Null:
					builder.Append("null");
					break;
			}
			return builder.ToString();
		}

		internal Route SubDepth(int count)
		{
			if (count <0)
			{
				Fuse.Diagnostics.InternalError( "count can't be < 0", this );
				return null;
			}
			
			if (count == 0)
				return this;
				
			if (SubRoute == null)
				return null;
				
			return SubRoute.SubDepth(count-1);
		}
		
	}
}
