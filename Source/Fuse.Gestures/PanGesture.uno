using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Gestures.Internal;
using Fuse.Input;
using Fuse.Motion.Simulation;
using Fuse.Scripting;
using Fuse.Triggers;

namespace Fuse.Gestures
{
	/**
		A @TransformGesture that provides panning (2D translation).

		This is triggered by two pointers (fingers) on the device moving together.

		For testing on desktop this can be triggered by holding down Shift, pressing the mouse button and moving. (This desktop feature is intended only for testing, so the specifics of how this works should not be relied upon.)
	*/
	public sealed class PanGesture : TransformGesture
	{
		[UXConstructor]
		public PanGesture([UXParameter("Target")] InteractiveTransform target)
			: base(target)
		{ }

		protected override void OnRooted()
		{
			base.OnRooted();
			Impl.Translated += OnTranslated;
		}
	
		protected override void OnUnrooted()
		{
			Impl.Translated -= OnTranslated;
			base.OnUnrooted();
		}
		
		float2 _startTranslation;
		FastMatrix _startTransform;
		float4x4 _invTransform;
		
		float2 _screenPrevTranslation, _screenStartTranslation;
		protected override void OnStarted()
		{
			_startTranslation = Target.Translation;
			_startTransform = FastMatrix.Identity();
			Target.AppendRotationScale(_startTransform);
			_invTransform = Matrix.Invert(_startTransform.Matrix );
			_screenStartTranslation = _screenPrevTranslation = 
				Vector.Transform(_startTranslation, _startTransform.Matrix ).XY;
			
			Region.Position = _screenStartTranslation;
			UpdateConstraint();
			Region.StartUser();
			CheckNeedUpdate();
		}
		
		protected override void OnEnded()
		{
			Region.EndUser();
			CheckNeedUpdate();
		}
		
		void UpdateConstraint()
		{
			var c = TranslationConstraint;
			Region.MinPosition = c.XY;
			Region.MaxPosition = c.ZW;
		}
		
		void OnTranslated(float2 dist)
		{
			UpdateConstraint();
			
			var screen = _screenStartTranslation + dist;
			var step = screen - _screenPrevTranslation;
			Region.StepUser(step);
			_screenPrevTranslation = screen;
			
			Target.Translation = Vector.Transform(Region.Position, _invTransform).XY;
		}
		
		protected override void OnUpdate()
		{
			Target.Translation = Vector.Transform(Region.Position, _invTransform).XY;
		}
	
		//TODO: this is invalid if the image is rotated!!!
		internal float4 TranslationConstraint
		{
			get
			{
				var hasSize = false;
				var size = float2(0);
				var trimSize = float2(0);
				
				if (_constrainElement != null)
				{
					size = _constrainElement.ActualSize;
					hasSize = true;
				}
				if (_sizeConstraint != null)
				{
					size = _sizeConstraint.ContentSize;
					trimSize = _sizeConstraint.TrimSize;
					hasSize = true;
				}
				
				if (hasSize)
				{
					// transform original bounds to find...
					var trans = FastMatrix.Identity();
					Target.AppendRotationScale(trans);
					var rect = new Rect(-size/2, size);
					var bounds = Rect.Transform(rect, trans.Matrix);
					
					//...extent over the original size..
					var full = bounds.Maximum;
					var over = Math.Max(float2(0), full - (size + trimSize) / 2);

					var c = float4(-over,over);
					return c;
				}
				
				return float4(float.NegativeInfinity,float.NegativeInfinity, float.PositiveInfinity, float.PositiveInfinity);
			}
		}
		
		Element _constrainElement;
		/**
			Constrains the gesture so the resulting scaled and translated @Visual will remain visible within the @ConstrainElement. That is, you can't pan it outside of the visible area.

			This assumes the visual content is the same size (when not transformed) as the element given here. For @Image use `Constraint` instead.

			## Example

			The circle in this example will always be visible in the light grey area when zoomed in and panned.

				<Panel HitTestMode="LocalBounds" Width="400" Height="400" ux:Name="TheWrapper" Color="#aaa" ClipToBounds="true">
					<Circle Color="#afa">
						<InteractiveTransform ux:Name="ImageTrans"/>
					</Circle>
					<ZoomGesture Target="ImageTrans"/>
					<PanGesture Target="ImageTrans" ConstrainElement="TheWrapper"/>
				</Panel>
		*/
		public Element ConstrainElement
		{
			get { return _constrainElement; }
			set 
			{ 
				_constrainElement = value; 
			}
		}
		
		ISizeConstraint _sizeConstraint;
		/**
			Constrains the gesture so the resulting scaled and translated item will remain visible. Unlike @ConstrainElement this works only with items exposing an @ISizeConstraint, such as @Image, but provides stricter bounds calculations (based on the actual visual content, not just the element bounds).

			## Example

			The zoomed image cannot be panned outside the extents of the control.

				<Panel HitTestMode="LocalBounds" Width="400" Height="400" Color="#aaa" ClipToBounds="true">
					<Image File="../../Assets/large_troll.jpg" ux:Name="TheImage">
						<InteractiveTransform ux:Name="ImageTrans"/>
					</Image>
					<ZoomGesture Target="ImageTrans"/>
					<PanGesture Target="ImageTrans" Constraint="TheImage"/>
				</Panel>
		*/
		public ISizeConstraint Constraint
		{
			get { return _sizeConstraint; }
			set
			{
				_sizeConstraint = value;
			}
		}
	}
}