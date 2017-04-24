using Uno;

using Fuse.Animations;
using Fuse.Motion.Simulation;

namespace Fuse.Motion
{
	/**
		This is a configuration object: it combines many options to make it simpler in UX for the user
		to setup and use the motion simulations. It also allows hiding the details of simulation from
		the UX level.

		This is a base class from which @ScrollViewMotion and @NavigationMotion are derived. When placed as the child of a @ScrollView or @Navigation (respectively), 
		they allow us to control certain aspects of the motions these elements perform.
	*/
	public class MotionConfig
	{
		BasicBoundedRegion2D _impl;

		protected MotionConfig() {}
		
		/**
			This is not a true factory method. It is expected that the object can be modified after
			creation by the provider. Multiple calls to this, without an intervening `ReleaseSimulation`
			should return the same object.
		*/
		internal BoundedRegion2D AcquireSimulation()
		{
			CreateImpl();
			return _impl;
		}
		
		/**
			Indicates the simulation is no longer being used, allowing the freeing of resources.
		*/
		internal void ReleaseSimulation()
		{
			_impl = null;
		}
		
		DestinationMotion<float2> _goto = new DestinationMotion<float2>();
		/**
			Specifies the motion for "Goto" or "MoveTo" style transitions.
		*/
		public DestinationMotion<float2> Goto
		{
			get { return _goto; }
		}

		/** Set/get the @DestinationMode.Type of `Goto`*/
		public MotionDestinationType GotoType
		{
			get { return _goto.Type; }
			set { _goto.Type = value; }
		}
		
		/** Set/get the @DestinationMotion.Easing of `Goto`  */
		public Easing GotoEasing
		{
			get { return _goto.Easing; }
			set { _goto.Easing = value; }
		}
		
		/** Set/get the @DestinationMotion.Duration of `Goto` */
		public float GotoDuration
		{
			get { return _goto.Duration; }
			set { _goto.Duration = value; }
		}
		
		/** Set/get the @DestinationMotion.DurationExp of `Goto` */
		public float GotoDurationExp
		{
			get { return _goto.DurationExp; }
			set { _goto.DurationExp = value; }
		}
		
		/** Set/get the @DestinationMotion.Distance of `Goto` */
		public float GotoDistance
		{
			get { return _goto.Distance; }
			set { _goto.Distance = value; }
		}
		
		DestinationMotion<float2> _snap = new DestinationMotion<float2>();
		/**
			Specifies the motion for "Snap" / overflow limitting transitions.
		*/
		public DestinationMotion<float2> Snap
		{
			get { return _snap; }
		}
		
		/** Set/get the @DestinationMotion.Type of `Snap` */
		public MotionDestinationType SnapType
		{
			get { return _snap.Type; }
			set { _snap.Type = value; }
		}
		
		/** Set/get the @DestinationMotion.Easing of `Snap` */
		public Easing SnapEasing
		{
			get { return _snap.Easing; }
			set { _snap.Easing = value; }
		}
		
		/** Set/get the @DestinationMotion.Duration of `Snap` */
		public float SnapDuration
		{
			get { return _snap.Duration; }
			set { _snap.Duration = value; }
		}
		
		/** Set/get the @DestinationMotion.DurationExp of `Snap` */
		public float SnapDurationExp
		{
			get { return _snap.DurationExp; }
			set { _snap.DurationExp = value; }
		}
		
		/** Set/get the @DestinationMotion.Distance of `Snap` */
		public float SnapDistance
		{
			get { return _snap.Distance; }
			set { _snap.Distance = value; }
		}
		
		OverflowType _overflow= OverflowType.Open;
		/**
			Specifies how user control is handled in the overflow area (when the user attempts to
			move beyond the maximum or minimum position.
			
			Note this defines only what happens when the user is interacting with the control in some way.
			Once the interaction is completed typically the `Snap` motion will bring the position back into
			bounds.
		*/
		public OverflowType Overflow
		{
			get { return _overflow; }
			set 
			{ 	
				_overflow = value; 
				if (_impl != null)
					_impl.Overflow = _overflow;
			}
		}
		
		float2 _overflowExtent = float2(150);
		/**
			For limited overflow types this specifies the logical extent of the overflow area.
		*/
		public float2 OverflowExtent
		{	
			get { return _overflowExtent; }
			set
			{
				_overflowExtent = value;
				if (_impl != null)
					_impl.OverflowExtent = _overflowExtent;
			}
		}

		/**
			The Unit specifies what type of value is being animated.
		*/
		public MotionUnit Unit
		{
			get { return _goto.Unit; }
			set
			{
				_goto.Unit = value;
				_snap.Unit = value;
			}
		}
		
		void CreateImpl()
		{
			_impl = new BasicBoundedRegion2D();
			_impl.DestinationSimulation = _goto.Create();
			_impl.SnapSimulation = _snap.Create();
			_impl.OverflowExtent = OverflowExtent;
			_impl.Overflow = Overflow;
			_impl.FrictionSimulation = Friction<float2>.CreateUnit(Unit);
		}
	}
	
	/**
		A configuration object for @Fuse.Navigation.StructuredNavigation
		This provides reasonable defaults for navigation and a good basis for customization.
	*/
	public class NavigationMotion : MotionConfig
	{
		public NavigationMotion()
		{
			Unit = MotionUnit.Normalized;
			
			//access the internals directly so these are seen as defautls and not explicit values
			Goto._type = MotionDestinationType.Easing;
			Goto._easing = Easing.SinusoidalInOut;
			
			Overflow = OverflowType.Clamp;
			OverflowExtent = float2(0.25f);
		}
	}
	
	/**
		A configuration object for @Fuse.Controls.ScrollView
		This provides reasonable defaults for scrolling and a good basis for customization.
	*/
	public class ScrollViewMotion : MotionConfig
	{
		public ScrollViewMotion()
		{	
			Unit = MotionUnit.Points;
			
			Goto._type = MotionDestinationType.Elastic;
			
			Snap._type = MotionDestinationType.SmoothSnap;
			
			Overflow = OverflowType.Elastic;
			OverflowExtent = float2(150);
		}
	}
}
