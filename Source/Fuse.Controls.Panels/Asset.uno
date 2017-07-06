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

        When used as a base class in UX markup, only one instance of the class with a given set of properties will actually have its 
        content rooted at any given time. The rest of the instances will simply reuse the cached bitmap result of the single rooted 
        instance.

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

        The content of a `Asset` UX markup tag are templates, not actual intances, hence `ux:Name`s are unreachable from the outside. 
        The template(s) will be instantiated if and only if the current intance becomes the master instance for a given set of property values. 

        The `ux:Property` properties on the class should be trivial value types. The uniqueness of an asset is determined by building
        a string hash by doing `.ToString()` on all the property values. If using non-trival value types which doesn't meaningfully
        override `ToString()`, it won't crash, but you might end up with incorrectly shared visual appearances between instances.

        An asset should not have any `Effects`, this will disable the benefits of using the class and generate a diagnostic error.
        Instead, put the effects on the contets of the class.

        Assets shuold not contain animations with duration. They may have triggers that respond instantly to changes properties
        (`ux:Property`) on the class, but not animate over time in response to property or data changes. This will not disply correctly.
    */
    [UXContentMode("TemplateIfClass")]
    public class Asset : LayoutControl, IPropertyListener
    {
        static Dictionary<string, List<Asset>> _rootedAssets = new Dictionary<string, List<Asset>>();

        static List<Asset> GetAssets(string hash)
        {
            List<Asset> assets;
            if (!_rootedAssets.TryGetValue(hash, out assets))
            {
                assets = new List<Asset>();
                _rootedAssets.Add(hash, assets);
            }
            return assets;
        }

        static Asset GetMaster(string hash)
        {
            return _rootedAssets[hash][0];
        }

        [UXAutoNameTable]
        public NameTable NameTable { get; set; }

        [UXAutoClassName]
        public string ClassName { get; set; }

        IDisposable _diag;
        void SetDiagnostic()
        {
            if (_diag == null)
                _diag = Diagnostics.ReportTemporalUserWarning("Assets should not have any effects - this prevents optimization. Place effects on its children instead", this);
        }
        void ClearDiagnostic()
        {
            if (_diag != null)
            {
                _diag.Dispose();
                _diag = null;
            }
        }

        protected override void OnRooted()
        {
            base.OnRooted();

            if (NameTable.Properties != null)
                for (var i = 0; i < NameTable.Properties.Count; i++)
                    NameTable.Properties[i].AddListener(this);

            AddToRegistry();
        }

        protected override void OnUnrooted()
        {
            ClearDiagnostic();

            if (NameTable.Properties != null)
                for (var i = 0; i < NameTable.Properties.Count; i++)
                    NameTable.Properties[i].RemoveListener(this);

            RemoveFromRegistry();

            base.OnUnrooted();
        }

        void AddToRegistry()
        {
            ComputeHash();

            var assets = GetAssets(_hash);
            assets.Add(this);
            if (assets.Count == 1) MakeMaster();  
        }

        void RemoveFromRegistry()
        {
            InvalidateCache();

            var assets = GetAssets(_hash);
            var thisIndex = assets.IndexOf(this);
            assets.RemoveAt(thisIndex);
            if (thisIndex == 0 && assets.Count > 0)
            {
                DisposeContent();
                assets[0].MakeMaster();
            }

            if (assets.Count == 0)
                _rootedAssets.Remove(_hash);

            InvalidateHash();
        }

        void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector property)
        {
            if (obj != NameTable.This) return;
            
            RemoveFromRegistry();
            AddToRegistry();
        }

        void MakeMaster()
        {
            if (GetMaster(_hash) != this) throw new Exception(); // shouldn't happen

            InstantiateContent();
        }

        string _hash;
        void ComputeHash()
        {
            if (_hash != null) return;

            var hash = ClassName;
            for (var i = 0; i < NameTable.Properties.Count; i++)
                hash += ";" + NameTable.Properties[i].GetAsObject().ToString();
            
            _hash = hash;
        }
        void InvalidateHash()
        {
            _hash = null;
        }

        void InstantiateContent()
        {
            for (var i = 0; i < Templates.Count; i++)
            {
                var t = Templates[i];
                var n = t.New() as Node;

                if (n != null) Children.Add(n);
            }
        }

        void DisposeContent()
        {
            Children.Clear();
        }
        
        framebuffer _cache; // Only the current master should have a non-null cache
        framebuffer ValidateCache(DrawContext dc)
        {
            if (_cache == null) 
                _cache = CaptureRegion(dc, LocalRenderBounds.FlatRect, float2(0));
            return _cache;
        }

        void InvalidateCache()
        {
            if (_cache != null)
            {
                FramebufferPool.Release(_cache);
                _cache = null;
            }
        }

        protected override float2 GetContentSize(LayoutParams lp)
        {
            var master = GetMaster(_hash);
            if (master == this) return base.GetContentSize(lp);
            else return master.GetContentSize(lp);
        }

        protected override void OnInvalidateVisual()
        {
            InvalidateCache();
            base.OnInvalidateVisual();
        }

        public override void Draw(DrawContext dc)
        {
            if (HasActiveEffects)
            {
                SetDiagnostic();
                base.Draw(dc);
                return;
            }
            
            ClearDiagnostic();

            var master = GetMaster(_hash);
            var cache = master.ValidateCache(dc);

            FreezeDrawable.Singleton.Draw(dc, this, Opacity, float2(1), master.LocalRenderBounds, cache);
        }
    }
}