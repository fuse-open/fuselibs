using Uno;
using Uno.UX;

namespace Fuse.Resources
{
	/** Specifies a hint for how a resource should be managed in memory.

		These settings are suggestions for how a resource may be loaded into memory, how it may be kept in memory, and when it can be unloaded. How these suggestions are interpreted will ultimately depend on the specific resource and what type it is.
	*/
	public sealed class MemoryPolicy
	{
		[UXGlobalResource("PreloadRetain")]
		/**
			This policy causes the resource to be loaded when the application starts and keep it in memory as long as possible.
		*/
		public static MemoryPolicy PreloadRetain = new MemoryPolicy{
			BundlePreload = true,
			};
			
		[UXGlobalResource("UnloadUnused")]
		/**
			This policy causes the resource to be loaded as required and then unloads it when no longer required (after a  timeout of 60s).
		*/
		public static MemoryPolicy UnloadUnused = new MemoryPolicy{
			UnloadInBackground = true,
			UnusedTimeout = 60,
			UnpinInvisible = true,
			};

		[UXGlobalResource("QuickUnload")]
		/**
			This policy causes the resource to be loaded as required and then unloads it as soon as possible when no longer required (after a  timeout of 1s).
			This is useful when you have several images being loaded dynamically one after the other in your app.
		*/
		public static MemoryPolicy QuickUnload = new MemoryPolicy{
			UnloadInBackground = true,
			UnusedTimeout = 1,
			UnpinInvisible = true,
			};
			
		[UXGlobalResource("UnloadInBackground")]
		/**
			Unloads the resource only when going into the background. This is meant primarily for internal resource use, where there is an alternate mechanism for cleaning unused items. Using it on high level resources, like Image, might cause memory exhaustion problems.
			
			@advanced
		*/
		public static MemoryPolicy UnloadInBackgroundPolicy = new MemoryPolicy{
			UnloadInBackground = true,
			};
			
		/** Specifies that a resource loaded from a bundle should be loaded as soon as possible during application startup. */
		public bool BundlePreload { get; set; }
		
		/** Specifies the resource should be unloaded when the application goes to the background. */
		public bool UnloadInBackground { get; set; }

		/** Specififes a timeout after which an unused resource can be released. */
		public double UnusedTimeout { get; set; }
		
		/** Allows a resource that is currently in use to be freed. For very static display components this can often work since the visuals may be cached anyway. */
		public bool AllowPinnedFree { get; set; }
		
		/** Specifies that a resource which is currently not visible (hidden), can be unpinned, and thus released. */
		public bool UnpinInvisible { get; set; }
		
		internal bool ShouldSoftDispose(DisposalRequest dr, IMemoryResource resource)
		{
			if (dr == DisposalRequest.Background && UnloadInBackground)
				return true;
				
			//desparation, free what we can
			if (dr == DisposalRequest.LowMemory && (!resource.IsPinned || AllowPinnedFree))
				return true;

			if ( (AllowPinnedFree || !resource.IsPinned) && UnusedTimeout > 0)
			{
				var elapsed = Time.FrameTime - resource.LastUsed;
				if (elapsed > UnusedTimeout)
					return true;
			}
			
			return false;
		}
	}
	
	interface IMemoryResource
	{
		MemoryPolicy MemoryPolicy { get; }
		bool IsPinned { get; }
		double LastUsed { get; }
		void SoftDispose();
	}
}