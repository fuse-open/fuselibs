using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Triggers;

namespace Fuse.Controls
{
	/*
		This is designed such that it could be moved up to Visual or Node if required -- as other 
		things that use ILoading will need to do the same thing.
		
		The interface points to move are:
			- OnPropertyChanged must call OnLoadingResourcePropertyChanged
			- OnRooted/OnUnrooted must call OnLoadingResourceRooted/Unrooted
	*/
	public abstract partial class Shape
	{
		static PropertyHandle _loadingResourcesHandle = Fuse.Properties.CreateHandle();

		//this tracks the watching status of each resources so it's safe to add/remove at any
		//time during rooting
		class ResourceWatcher
		{
			public bool IsWatching;
		}
		Dictionary<PropertyObject, ResourceWatcher> LoadingResources
		{
			get
			{
				object val;
				Dictionary<PropertyObject,ResourceWatcher> loading;
				if (Properties.TryGet(_loadingResourcesHandle, out val))
				{
					loading = (Dictionary<PropertyObject,ResourceWatcher>)val;
				}
				else
				{
					loading = new Dictionary<PropertyObject,ResourceWatcher>();
					Properties.Set(_loadingResourcesHandle, loading);
				}
				
				return loading;
			}
		}
		
		bool HasLoadingResources
		{
			get { return Properties.Has(_loadingResourcesHandle); }
		}
		
		internal void AddLoadingResource( PropertyObject res ) 
		{
			if (!(res is ILoading))
				return;
				
			var all = LoadingResources;
			ResourceWatcher watcher;
			if (!all.TryGetValue(res, out watcher))
			{
				watcher = new ResourceWatcher();
				all[res] = watcher;
			}
			
			if (IsRootingStarted && !watcher.IsWatching)
			{
				res.AddPropertyListener(this);
				watcher.IsWatching = true;
			}
		}
		
		internal void RemoveLoadingResource( PropertyObject res )
		{
			if (!(res is ILoading))
				return;
				
			var all = LoadingResources;
			ResourceWatcher watcher;
			if (!all.TryGetValue(res, out watcher))
				return;
				
			if (watcher.IsWatching)
			{
				res.RemovePropertyListener(this);
				watcher.IsWatching = false;
			}
			
			all.Remove(res);
		}
		
		internal void OnLoadingResourcePropertyChanged( PropertyObject sender, Selector property )
		{
			var loading = sender as ILoading;
			if (!HasLoadingResources || loading == null)
				return;
				
			if (property != ILoadingStatic.IsLoadingName)
				return;
				
			CheckStatus();
		}
		
		internal void OnLoadingResourceRooted()
		{
			if (HasLoadingResources)
			{
				foreach (var item in LoadingResources)
				{
					if (item.Value.IsWatching)
						continue;
					item.Key.AddPropertyListener(this);
					item.Value.IsWatching = true;
				}
			}
			CheckStatus();
		}
		
		internal void OnLoadingResourceUnrooted()
		{
			if (!HasLoadingResources)
				return;
				
			foreach (var item in LoadingResources)
			{
				if (item.Value.IsWatching)
					item.Key.RemovePropertyListener(this);
				item.Value.IsWatching = false;
			}
		}
		
		BusyTask _loadingResourceTask;
		
		void CheckStatus()
		{
			var loading = false;
			if (HasLoadingResources)
			{
				foreach (var item in LoadingResources)
				{	
					if ((item.Key as ILoading).IsLoading)
					{
						loading = true;
						break;
					}
				}
			}

			BusyTask.SetBusy(this, ref _loadingResourceTask, loading ? BusyTaskActivity.Loading :
				BusyTaskActivity.None);
		}
		
	}
}