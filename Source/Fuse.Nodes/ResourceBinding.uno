using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Resources
{
	interface IResourceConverter<T>
	{
		bool Accept(object o);
		T Convert(object o);
	}

	abstract class NumericResourceConverter<T> : IResourceConverter<T>
	{
		public bool Accept(object o)
		{
			var q = o is float || o is int || o is double;
			return q;
		}
		protected double InternConvert(object o)
		{
			if (o is float)
				return (float)o;
			if (o is double)
				return (double)o;
			if (o is int)
				return (int)o;
			return 0;
		}
		public abstract T Convert(object o);
	}
	class FloatResourceConverter : NumericResourceConverter<float>
	{
		public override float Convert(object o) { return (float)InternConvert(o); }
	}
	class DoubleResourceConverter : NumericResourceConverter<double>
	{
		public override double Convert(object o) { return (double)InternConvert(o); }
	}
	class IntResourceConverter : NumericResourceConverter<int>
	{
		public override int Convert(object o) { return (int)InternConvert(o); }
	}

	class GenericResourceConverter<T> : IResourceConverter<T>
	{
		public bool Accept(object o)
		{
			return o is T;
		}

		public T Convert(object o)
		{
			return (T)o;
		}
	}

	/**
		Special conversions to allow ResourceBinding to convert between types, otherwise
		mismatched resource don't work.
	*/
	static class ResourceConverters
	{
		static Dictionary<Type, object> _converters = new Dictionary<Type,object>();

		static public IResourceConverter<T> Get<T>()
		{
			object converter;
			if (!_converters.TryGetValue(typeof(T), out converter))
			{
				if (typeof(T) == typeof(float))
					converter = new FloatResourceConverter();
				else if (typeof(T) == typeof(double))
					converter = new DoubleResourceConverter();
				else if (typeof(T) == typeof(int))
					converter = new IntResourceConverter();
				else
					converter = new GenericResourceConverter<T>();

				_converters.Add(typeof(T),converter);
			}

			return (IResourceConverter<T>)converter;
		}
	}


	[UXAutoGeneric("ResourceBinding", "Target")]
	[UXValueBindingAlias("Resource")]
	/**
		Binds a property to the value of a resource.
		
		This example creates a global @Font resource with the key `Bold` and binds it to the `Font` property of @Text.
		
			<Font File="Assets/Roboto-Italic.ttf" ux:Key="Italic"/>
			
			<Text Value="Sample" Font="{Resource Italic}"/>
			
		The binding looks for the most local definition of the resource with a given key. In the following example the bindings are all for the key "Standard", but the more local definition in the second panel takes precedence.

			<Panel>
				<Font File="Assets/Roboto.ttf" ux:Key="Standard"/>
				<Text Value="Uses Roboto" Font="{Resource Standard}"/>
				
				<Panel>
					<Font File="Assets/Impact.ttf" ux:Key="Standard"/>
					<Text Value="Uses Impact" Font="{Resource Standard}"/>
				</Panel>
				
				<Text Value="Uses Roboto" Font="{Resource Standard}"/>
			</Panel>

		@see Fuse.Reactive.DataToResource
	*/
	public sealed class ResourceBinding<T>: Binding
	{
		[UXValueBindingTarget]
		public Property<T> Target { get; private set; }

		[UXValueBindingArgument]
		public string Key { get; private set; }

		[UXConstructor]
		public ResourceBinding([UXParameter("Target")] Property<T> target, [UXParameter("Key")] string key)
		{
			if (target == null) throw new ArgumentNullException("target");
			Target = target;
			Key = key;
		}

		IResourceConverter<T> _converter;

		protected override void OnRooted()
		{
			_converter = ResourceConverters.Get<T>();
			ResourceRegistry.AddResourceChangedHandler(Key, OnChanged);
			OnChanged();
		}

		protected override void OnUnrooted()
		{
			ResourceRegistry.RemoveResourceChangedHandler(Key, OnChanged);
		}

		void OnChanged()
		{
			object resource;
			if (Parent.TryGetResource(Key, _converter.Accept, out resource))
			{
				Target.Set(_converter.Convert(resource), null);
			}
		}
	}
}
