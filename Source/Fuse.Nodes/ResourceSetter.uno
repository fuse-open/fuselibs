using Uno;
using Uno.UX;

namespace Fuse.Resources
{
	[UXAutoGeneric("ResourceSetter","Value")]
	/**
		Creates or overrides a resource with the given key.
		
		Note that static resources are better declared with `ux:Key`. The `ResourceSetter` types are to be used when a dynamic value is needed, or one that cannot be expressed with `ux:Key`.
		
			<Panel>
				<string Value="Static Page Title" ux:Key="Title"/>
			</Panel>
			<Each Items="{items}">
				<Panel>
					<ResourceString Key="Title" Value="{pageTitle}"/>
				</Panel>
			</Each>
		
		The resources created via `ResourceSetter` are local to where they are defined (this is also true of `ux:Key`). Bindings in this node, and its descendents, can bind to the them. Descendents may also provide a new resource with the same `Key`, which overrides it for that part of the UI tree.
		
		@see @Fuse.Resources.ResourceBinding
		@see @Fuse.Reactive.DataToResource
	*/
	public abstract class ResourceSetter<T> : Behavior
	{
		string _key;
		public string Key
		{
			get { return _key; }
			set
			{
				_key = value;
				OnChanged();
			}
		}

		T _value;
		public T Value
		{
			get { return _value; }
			set
			{
				if ( !object.Equals(_value,value) )
				{
					_value = value;
					OnChanged();
				}
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			OnChanged();
		}

		void OnChanged()
		{
			if (Parent != null && _key != null)
			{
				Parent.SetResource( _key, _value );
			}
		}
	}

	public sealed class ResourceString : ResourceSetter<string> { }
	public sealed class ResourceObject : ResourceSetter<object> { }
	public sealed class ResourceBool : ResourceSetter<bool> { }
	public sealed class ResourceFloat : ResourceSetter<float> { }
	public sealed class ResourceFloat2 : ResourceSetter<float2> { }
	public sealed class ResourceFloat3 : ResourceSetter<float3> { }
	public sealed class ResourceFloat4 : ResourceSetter<float4> { }
}
