using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse.Controls
{
	/** A control where the visual appearance is shared between all instances sharing a class identity and the same property values. Used for optimization.

		This class can be used as an optimization when an app contains multiple instances of a class which has the same static visual
		appearance across all instances with the same values for its `ux:Property`s, for example a class that displays an icon from a 
		icon font and adds a shadow.
		
		The appearance doesn't have to be the same on different devices or under different settings, as long as it is the same for all
		instances being active (rooted) at the same time, with the same `ux:Property` values. It is the user's responsibility to ensure 
		this to allow this class to optimize under that assumption.

		## Example use

		Let's say we define an icon class, like so:

			<Asset ux:Class="MyApp.FooIcon">
				<string ux:Property="Icon" />
				<Text Value="{Property Icon}" />
					<DropShadow />
				</Image>
			</Asset>

		And used elsewhere like this:

			<MyApp.FooIcon Icon="&#xE343;" />

		## Remarks

		The `ux:Property` properties on the class should be trivial value types. The uniqueness of an asset is determined by building
		a string hash by doing `.ToString()` on all the property values. If using non-trival value types which doesn't meaningfully
		override `ToString()`, it won't crash, but you might end up with incorrectly shared visual appearances between instances.

		Assets shuold not contain animations with duration. They may have triggers that respond instantly to changes properties
		(`ux:Property`) on the class, but not animate over time in response to property or data changes. This will not disply correctly.
	*/
	public class Asset : LayoutControl, IPropertyListener
	{
		internal class Cache
		{
			public readonly List<Asset> Assets = new List<Asset>();
			public Asset Master { get { return Assets[0]; } }
			
			framebuffer Bitmap;

			public framebuffer Validate(DrawContext dc)
			{
				if (Bitmap == null) 
				{
					Master._painting = true;
					Bitmap = Master.CaptureRegion(dc, Master.LocalRenderBounds.FlatRect, float2(0));
					Master._painting = false;
				}
				return Bitmap;
			}

			public void Invalidate()
			{
				if (Bitmap != null)
				{
					FramebufferPool.Release(Bitmap);
					Bitmap = null;
				}
			}
		}

		// Internal for testing purposes
		internal static Dictionary<string, Cache> _rootedAssets = new Dictionary<string, Cache>();
		


		static Cache GetCache(string hash)
		{
			Cache assets;
			if (!_rootedAssets.TryGetValue(hash, out assets))
			{
				assets = new Cache();
				_rootedAssets.Add(hash, assets);
			}
			return assets;
		}

		static Asset GetMaster(string hash)
		{
			return _rootedAssets[hash].Master;
		}

		[UXAutoNameTable, UXOnlyAutoIfClass]
		public NameTable NameTable { get; set; }

		[UXAutoClassName, UXOnlyAutoIfClass]
		public string ClassName { get; set; }

		bool _rooted;
		protected override void OnRooted()
		{
			base.OnRooted();

			if (NameTable.Properties != null)
				for (var i = 0; i < NameTable.Properties.Count; i++)
					NameTable.Properties[i].AddListener(this);

			if (IsVisible) AddToRegistry();
			_rooted = true;
		}

		protected override void OnIsVisibleChanged()
		{
			base.OnIsVisibleChanged();
			if (_rooted)
			{
				if (IsVisible) AddToRegistry();
				else RemoveFromRegistry();
			}
		}

		protected override void OnUnrooted()
		{
			if (NameTable.Properties != null)
				for (var i = 0; i < NameTable.Properties.Count; i++)
					NameTable.Properties[i].RemoveListener(this);

			if (IsVisible) RemoveFromRegistry();
			_rooted = false;

			base.OnUnrooted();
		}

		bool _inRegistry;

		void AddToRegistry()
		{
			_inRegistry = true;
			
			ComputeHash();

			var cache = GetCache(_hash);
			cache.Assets.Add(this);
		}

		void RemoveFromRegistry()
		{
			_inRegistry = false;

			var cache = GetCache(_hash);
			var thisIndex = cache.Assets.IndexOf(this);
			cache.Assets.RemoveAt(thisIndex);

			InvalidateHash();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector property)
		{
			if (obj != NameTable.This) return;
			
			RemoveFromRegistry();
			AddToRegistry();
		}

		static string MakeHash(object obj)
		{
			if (obj == null) return "null";
			if (obj is string) return "\"" + (string)obj + "\"";
			return obj.ToString();
		}

		string _hash;
		void ComputeHash()
		{
			if (_hash != null) return;

			var hash = ClassName;
			for (var i = 0; i < NameTable.Properties.Count; i++)
				hash += ";" + MakeHash(NameTable.Properties[i].GetAsObject());
			
			_hash = hash;
		}
		void InvalidateHash()
		{
			_hash = null;
		}

		bool _painting;

		protected override void OnInvalidateVisual()
		{
			if (_inRegistry)
			{
				ComputeHash();
				var cache = GetCache(_hash);
				if (cache.Master == this) cache.Invalidate();
			}
			base.OnInvalidateVisual();
		}

		protected override void DrawWithChildren(DrawContext dc)
		{
			if (_painting)
			{
				base.DrawWithChildren(dc);
				return;
			}
			
			var cache = GetCache(_hash);
			var bitmap = cache.Validate(dc);

			FreezeDrawable.Singleton.Draw(dc, this, Opacity, float2(1), cache.Master.LocalRenderBounds, bitmap);
		}
	}
}