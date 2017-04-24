using Uno;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Animations;
using Fuse.Controls;
using Fuse.Triggers;

namespace AnimationTests.Test
{
	public class Timestamp
	{
		public float TimeDelta { get;set; }
		public float4 ExpectedValue { get;set; }

		public Timestamp()
		{
		}

		public Timestamp(float timeDelta, float expectedValue) : this(timeDelta, float4(expectedValue))
		{
		}

		public Timestamp(float timeDelta, float4 expectedValue)
		{
			TimeDelta = timeDelta;
			ExpectedValue = expectedValue;
		}

		public Timestamp(float timeDelta, float animationValue, float animationProgress, Easing animationFunction, AnimationVariant direction) : this(timeDelta, animationValue, animationProgress, 0, animationFunction, direction)
		{
		}

		public Timestamp(float timeDelta, float animationValue, float animationProgress, float animationOffset, Easing animationFunction, AnimationVariant direction)
		{
			TimeDelta = timeDelta;
			if (direction == AnimationVariant.Forward)
				ExpectedValue = float4(animationOffset + animationValue * (float)animationFunction.Map(animationProgress));
			else
				ExpectedValue = float4(animationOffset + animationValue * (1 - (float)animationFunction.Map(animationProgress)));
		}

		public Timestamp(float timeDelta, float4 animationValue, float animationProgress, float4 animationOffset, Easing animationFunction, AnimationVariant direction)
		{
			TimeDelta = timeDelta;
			if (direction == AnimationVariant.Forward)
				ExpectedValue = animationOffset + animationValue * (float)animationFunction.Map(animationProgress);
			else
				ExpectedValue = animationOffset + animationValue * (1 - (float)animationFunction.Map(animationProgress));
		}
	}
}
