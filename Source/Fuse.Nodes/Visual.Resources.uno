using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Resources;

namespace Fuse
{
	public partial class Visual
	{
		static PropertyHandle _resourcesHandle = Fuse.Properties.CreateHandle();

		[UXContent]
		/** The list of resources defined at this node. */
		public IList<Resource> Resources
		{
			get
			{
				if (!HasResources)
				{
					SetBit(VisualBits.Resources);
					var list = new RootableList<Resource>();
					if (IsRootingCompleted)
						list.Subscribe(OnResourceChanged, OnResourceChanged);
					Properties.Set(_resourcesHandle, list);
				}
				return (IList<Resource>)Properties.Get(_resourcesHandle);
			}
		}

		void RootResources()
		{
			if (HasResources)
			{
				var list = (RootableList<Resource>)Resources;
				list.Subscribe(OnResourceChanged,OnResourceChanged);
				
				//TODO: it feels as though this shouldn't be needed during rooting, but there's one
				//test that somehow exhibits the need for it.
				for (int i=0; i < list.Count; ++i)
					OnResourceChanged(list[i]);
			}
		}
		
		void UnrootResources()
		{
			if (HasResources)
			{
				var list = (RootableList<Resource>)Resources;
				list.Unsubscribe();
			}
		}
		
		public void SetResource(string key, object value)
		{
			var resources = Resources;
			for (int i=0; i < resources.Count; ++i)
			{
				var r = resources[i];
				if (r.Key == key)
				{
					//TODO: we need to replace somehow, otherwise OnResourceChange is called twice
					resources.RemoveAt(i);
					break;
				}
			}
			
			resources.Add( new Resource(key, value) );
		}
		
		public override bool TryGetResource(string key, Predicate<object> acceptor, out object resource)
		{
			if (HasResources)
			{
				var resources = Resources;
				for (int i = 0; i < resources.Count; i++)
				{
					var r = resources[i];
					if (r.Key == key && (acceptor == null || acceptor(r.Value)))
					{
						resource = r.Value;
						return true;
					}
				}
			}

			if (ContextParent != null)
				return ContextParent.TryGetResource(key, acceptor, out resource);

			return Uno.UX.Resource.TryFindGlobal(key, acceptor, out resource);
		}

		bool HasResources
		{
			get { return HasBit(VisualBits.Resources); }	
		}
		
		void OnResourceChanged(Resource res)
		{
			Fuse.Resources.ResourceRegistry.NotifyResourceChanged(res.Key);
		}
	}

}
