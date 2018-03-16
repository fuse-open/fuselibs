using Uno;
using Uno.UX;

namespace Fuse.Animations
{
	static class RangeAdapterHelpers
	{
		internal static Selector _valueName = "Value";
	}

	/*
		TODO: https://github.com/fusetools/fuselibs-private/issues/1344
		This is really meant to have the `Value` as just a `double`, not a generic. In particular for
		the Source/ValueRange properties.
	*/
	/**
		Changes the range of an animation.

		This allows finer control over animations such as `Timeline` and `..Animation`triggers.

		# Example
		In the following example, a rotation of 90 degrees will be adapted into a rotation of 45 degrees by using a `RangeAdapter` to change the range our `WhilePressed` trigger:

			<Panel Alignment="Center" Width="200" Height="200">
				<Rectangle Color="#2196F3" CornerRadius="5" />
				<Timeline ux:Name="rotationTimeline">
					<Rotate DegreesZ="90" Duration="1"/>
				</Timeline>
				<RangeAdapter ux:Name="range" Source="rotationTimeline.Progress" SourceRangeMax=".5" SourceRangeMin="0" />
				<WhilePressed>
					<Change range.Value="1" Duration="1"/>
				</WhilePressed>
			</Panel>
	*/
	[UXAutoGeneric("RangeAdapter","Source")]
	public sealed class RangeAdapter<T> : Behavior, IPropertyListener
	{
		public Property<T> Source { get; private set; }
		
		Fuse.Internal.ScalarBlender<T> _blender = Fuse.Internal.BlenderMap.GetScalar<T>();
		
		[UXConstructor]
		public RangeAdapter([UXParameter("Source")] Property<T> source)
		{
			Source = source;
		}

		/**
			The value to be translated. Change this to have `Source` updated with the translated value.
		*/
		[UXOriginSetter("SetValue")]
		public T Value
		{
			get { return Out(Source.Get()); }
			set { SetValue(value, this); }
		}
		
		public void SetValue(T value, IPropertyListener origin)
		{
			Source.Set( In(value), origin );
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			Source.AddListener(this);
		}
		
		protected override void OnUnrooted()
		{
			Source.RemoveListener(this);
			base.OnUnrooted();
		}

		
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector sel)
		{
			OnPropertyChanged(RangeAdapterHelpers._valueName);
		}
		
		double _sourceRangeMin = 0, _sourceRangeMax = 1;
		/**
			The minimum value to map to on the source
		*/
		public T SourceRangeMin 
		{
			get { return _blender.FromDouble(_sourceRangeMin); }
			set { _sourceRangeMin = _blender.ToDouble(value); }
		}

		/**
			The maximum value to map to on the source
		*/
		public T SourceRangeMax
		{
			get { return _blender.FromDouble(_sourceRangeMax); }
			set { _sourceRangeMax = _blender.ToDouble(value); }
		}
		
		double _valueRangeMin = 0, _valueRangeMax = 1;
		/**
			The minimum value to map to on the value. Default: 0
		*/
		public T ValueRangeMin 
		{
			get { return _blender.FromDouble(_valueRangeMin); }
			set { _valueRangeMin = _blender.ToDouble(value); }
		}

		/**
			The maximum value to map to on the value. Default: 1
		*/
		public T ValueRangeMax
		{
			get { return _blender.FromDouble(_valueRangeMax); }
			set { _valueRangeMax = _blender.ToDouble(value); }
		}
		
		//from Source => Value
		T Out(T value)
		{
			var src = _blender.ToDouble(value);
			var rel = (src - _sourceRangeMin) / (_sourceRangeMax - _sourceRangeMin);
			var dst = rel * (_valueRangeMax - _valueRangeMin) + _valueRangeMin;
			return _blender.FromDouble(dst);
		}
		
		//from Value => Source
		T In(T value)
		{
			var dst = _blender.ToDouble(value);
			var rel = (dst - _valueRangeMin) / (_valueRangeMax - _valueRangeMin);
			var src = rel * (_sourceRangeMax - _sourceRangeMin) + _sourceRangeMin;
			return _blender.FromDouble(src);
		}
	}
}
