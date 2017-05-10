using Uno;

namespace Fuse.Internal
{
	/**
		Store settings that change how Fuse operates. In particular this should
		store toggles to turn on/off optmisations.
		
		All values should be "true" here for a release build.
	*/
	static class FuseConfig
	{
		public const bool VisualHitTestClipping = true;
		
		public const bool AllowElementDrawCache = true;
		
		public const bool EnableElementEffects = true;
	}
}
