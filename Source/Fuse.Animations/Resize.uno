using Uno;

namespace Fuse.Animations
{
	public interface IResize
	{
		void SetSize(float2 size);
	}

	public interface IResizeMode
	{
		bool GetSizeChange(Visual target, Visual relative, out float2 baseSize, out float2 deltaSize);
	}

	/**
		An @Animator that changes the size of an @Element.
		
		This is typically used as part of a @LayoutAnimation.

		The size is considered a temporary size for the element, not it's true intended size. When the animator is disabled the natural size will be restored.

		# Example
		
			<Panel>
				<LayoutAnimation>
					<Resize RelativeTo="SizeChange" Duration="1" Vector="1"/>
					<Move RelativeTo="PositionChange" Duration="1" Vector="1"/>
				</LayoutAnimation>
			</Panel>
			
	*/
	public class Resize: TrackAnimator
	{
		/** An alternate target for the resize, instead of the default: the parent of the animator */
		public Visual Target { get; set; }

		/** Relative to which node, used in combination with `RelativeTo` */
		public Visual RelativeNode { get; set; }
		
		IResizeMode _resizeMode;
		/**
			Specifies how the size for `Resize` is calculated. This is the size that will be applied when at Progress=1.
			
				* `SizeChange`: The size of the element prior to the most recent layout change.
				* `Size`: The size of `RelativeNode`
		*/
		public IResizeMode RelativeTo 
		{ 
			get { return _resizeMode; }
			set { _resizeMode = value; }
		}
		
		/** The `X` value of `Vector` */
		public float X
		{
			get { return _vectorValue.X; }
			set { _vectorValue.X = value; }
		}
		
		/** The `Y` value of `Vector` */
		public float Y
		{
			get { return _vectorValue.Y; }
			set { _vectorValue.Y = value; }
		}
		
		/**
			Specifies the factor of the size to apply to each dimension.
			
			The default if `0`. The most common use-case is to have `Vector="1"`.
		*/
		public float2 Vector
		{
			get { return _vectorValue.XY; }
			set { _vectorValue = float4(value, _vectorValue.ZW); }
		}

		internal override AnimatorState CreateState(CreateStateParams p)
		{
			return new ResizeAnimatorState(this, p);
		} 
	}

	class ResizeAnimatorState: TrackAnimatorState
	{
		Resize _resize;
		IResize _target;
		bool _valid = true;
		IResizeMode _relativeTo;
		Visual _relativeNode;

		public ResizeAnimatorState(Resize r, CreateStateParams p): base(r, p, r.Target)
		{
			_resize = r;
			_target = Visual as IResize;
			if (_target == null)
			{
				Fuse.Diagnostics.InternalError( "Resize started without a Target node", r );
				_valid = false;
				return;
			}
			
			_relativeTo = r.RelativeTo;
			if (_relativeTo == null)
			{
				Fuse.Diagnostics.InternalError( "Resize started without as RelativeTo", r );
				_valid = false;
				return;
			}
			
			_relativeNode = _resize.RelativeNode ?? Visual;
			//watch for changes in relative node
			var elm = _relativeNode as IActualPlacement;
			if (elm != null)
				elm.Placed += OnPlaced;
			
			//if target node is modified we reapply our settings (we win!)
			var e = _target as IActualPlacement;
			if (e != null)
				e.Placed += OnPlaced;
		}
		
		public override void Disable()
		{
			base.Disable();
			if (!_valid)
				return;
				
			var e = _target as IActualPlacement;
			if (e != null)
				e.Placed -= OnPlaced;
			
			var elm = _relativeNode as IActualPlacement;
			if (elm != null)
				elm.Placed -= OnPlaced;
		}

		float4 _lastValue;
		float _lastStrength;
		protected override void SeekValue(float4 value, float strength)
		{
			_lastStrength = strength;
			_lastValue = value;
			Update(value, strength);
		}
		
		void Update(float4 value, float strength)
		{
			if (!_valid)
				return;

			float2 baseSize;
			float2 deltaSize;

			if (_relativeTo.GetSizeChange(Visual, _relativeNode, out baseSize, out deltaSize))
			{
				var sz = baseSize + deltaSize*value.XY*strength;
				_target.SetSize(sz);
			}
		}
		
		void OnPlaced(object s, object a)
		{
			Update(_lastValue, _lastStrength);
		}
	}
}
