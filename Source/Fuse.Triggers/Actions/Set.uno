using Uno;
using Uno.UX;

namespace Uno.UX
{
	public delegate T Expression<T>();
}

namespace Fuse.Triggers.Actions
{
	[UXAutoGeneric("Set","Target")]
	/**
		Permanently changes the value of a property.
		
		> **Note:** If you wish to temporarily change the value of a property, use @Change instead.
		
		The basic syntax of `Set` is as follows:
		
			<Set myNode.MyProperty="MyValue" />
		
		However, this is just syntactic sugar. The following is equivalent:
		
			<Set Target="myNode.MyProperty" Value="MyValue" />
		
		## Example
		
		The following example consists of a red @Rectangle that, once clicked, changes its color to blue.
		
			<Rectangle ux:Name="myRectangle" Color="Red">
				<Clicked>
					<Set myRectangle.Color="Blue" />
				</Clicked>
			</Rectangle>
	*/
	public class Set<T> : TriggerAction
	{
		/** The property to assign to.
			
			## Example
			
				<Button Text="Make background blue">
					<Clicked>
						<Set Target="background.Color" Value="Blue" />
					</Clicked>
				</Button>
				<Rectangle ux:Name="background" Color="Red" />
		*/
		public Property<T> Target { get; private set; }
		
		/** The value to assign to the target property.
			
			This can either be a constant value or a [data binding](api:fuse/reactive/databinding).
		*/
		public T Value { get; set; }
		
		/** @advanced */
		public Expression<T> Expression { get; set; }
		
		[UXConstructor]
		public Set([UXParameter("Target")] Property<T> target)
		{
			if (target == null)
				throw new ArgumentNullException(nameof(target));

			Target = target;
		}
		
		void Update(T value)
		{
			Target.Set(value, null);
		}
		
		protected override void Perform(Node target)
		{
			if (_hasIncrement)
				Update(_blender.Add(Target.Get(),_increment));
			else if (Expression != null)
				Update(Expression());
			else
				Update(Value);
		}
		
		T _increment;
		bool _hasIncrement;
		/** 
			If specified, `Set` will increment the target property by the provided amount rather than overwriting it.
			
			## Example
			
			The following example consists of a red @Rectangle and a button that fades its color
			a little step towards blue with each click.
			
				<Button Text="Make background more blue">
					<Clicked>
						<Set Target="background.Color" Increment="-0.2, 0, 0.2, 0" />
					</Clicked>
				</Button>
				<Rectangle ux:Name="background" Color="1, 0, 0, 1" />
		*/
		public T Increment 
		{ 
			get { return _increment; }
			set
			{
				_increment = value;
				_hasIncrement = true;
				if (_blender == null)
					_blender = Fuse.Internal.BlenderMap.Get<T>();
			}
		}
		Fuse.Internal.Blender<T> _blender;
	}
	
}
