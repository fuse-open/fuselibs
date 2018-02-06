using Uno;

namespace Fuse.Navigation
{		
	delegate void RouterPageChangedHandler(object sender, RouterPage newPage);
	
	/**
		Extends a Visual that is being used as a page. Only pages should contain this information as it will be presumed that the presence of this data indicates a Visual is a page.
		
		This structure is required since anything can be used as a page: there is no special page type.
	*/
	class PageData
	{
		[WeakReference]
		public Visual Visual { get; private set; }
		
		//managed by the Navigation object
		public int Index;
		public float Progress;
		public float PreviousProgress;
		
		//reserved for the ControlPageData objects in Fuse.Controls.Navigation. Avoids creating added
		//dynamic properties
		public object ControlPageData;

		//the current RouterPage attached to this visual
		public RouterPage RouterPage { get; private set; }
	
		public event RouterPageChangedHandler RouterPageChanged;

		public object Context { get; private set; }
		
		public PageData( Visual visual ) 
		{
			Visual = visual;
		}

		public void AttachRouterPage(RouterPage rp)
		{
			var visual = Visual;
			if (visual == null)
			{
				Fuse.Diagnostics.InternalError( "Attaching to null page", this );
				return;
			}
			
			this.RouterPage = rp;
			UpdateContextData( visual, rp.Context );
			visual.Prepare(rp.Parameter);
			
			if (RouterPageChanged != null)
				RouterPageChanged( this, rp );
		}
		
		void UpdateContextData( Visual page, object data )
		{
			var oldData = Context;
			Context = data;
			page.BroadcastDataChange(oldData, data);
		}
		
		//TODO: temporary  until PageControl is migrated better
		public void SetContext( object data )
		{
			UpdateContextData( Visual, data );
		}
		
		static PropertyHandle _propPageData = Properties.CreateHandle();
		
		static public PageData GetOrCreate(Visual v, bool allowCreate = true)
		{
			object res;
			if (v.Properties.TryGet(_propPageData, out res))
				return (PageData)res;

			if (!allowCreate)	
				return null;
				
			var pd = new PageData(v);
			v.Properties.Set(_propPageData, pd);
			return pd;
		}
		
		static public PageData Get(Visual v)
		{
			return GetOrCreate(v, false);
		}
		
	}
}