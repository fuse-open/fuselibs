using Uno;

namespace Fuse.Motion
{
	/**
		Specifies how to treat movement in the overflow area: the area in a bounded region that is beyond
		the logical limits, such as the area beyond the ends of the `ScrollView` content, or beyond the
		first/last page of navigation.
	*/
	public enum OverflowType
	{
		/** Movement is unrestricted and continues into overflow area */
		Open,
		/** The value is hard-clamped at the bounds */
		Clamp,
		/** The movement has a dimishing influence on the actual value as it extends into the overflow area */
		Elastic,
	}
	
	/**
		The basic motion types. This defines the algorithm being used to perform animation of a value.
	*/
	public enum MotionDestinationType
	{
		/** A standard easing. */
		Easing,
		/** A physics based attraction force. This typically results in fluid movement that bounces a bit around the target value */
		Elastic,
		/** A common snapping model that uses constant speed then constant acceleration to slow-down. */
		SmoothSnap,
	}

	/**
		The unit of the value being animated.
	*/
	public enum MotionUnit
	{	
		/** Fuse virtual points, typical for a `ScrollView` or other `Element` size property */
		Points,
		/** Normalized values are those where `1` represents a full unit of movement, such as a page in navigation */
		Normalized,
		/** Measures an angular value in radians. This is a wrapping value. */
		Radians,
		/** Measures an angular value in degress. This is a wrapping value. */
		Degrees,
	}

}