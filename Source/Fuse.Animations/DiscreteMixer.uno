using Uno;
using Uno.Collections;
using Fuse;

namespace Fuse.Animations
{
	// highest strenght wins in the discrete mixer (< 0.5 results in rest state)
	class DiscreteMixer : MixerBase
	{
		protected override MasterProperty<T> CreateMaster<T>( Uno.UX.Property<T> property,
			MixerBase mixerBase )
		{ return new DiscreteMasterProperty<T>(property, mixerBase); }
		protected override MasterBase<Transform> CreateMasterTransform( Visual element,
			MixerBase mixerBase)
		{ return new DiscreteMasterTransform(element, mixerBase); }
	}
	
	class DiscreteMasterProperty<T> : MasterProperty<T>
	{
		public DiscreteMasterProperty( Uno.UX.Property<T> property, MixerBase mixerBase ) 
			: base(property, mixerBase) { }
		
		public override void OnComplete()
		{
			T nv = RestValue;
			float str = 0.5f;
			for (int i=0; i < Handles.Count; ++i)
			{
				var v = Handles[i];
				if( v.HasValue && v.Strength > str)
				{
					nv = v.Value;
					str = v.Strength;
				}
			}
				
			Set(nv);
		}
	}
	
	class DiscreteMasterTransform : MasterTransform
	{
		public DiscreteMasterTransform( Visual node, MixerBase mixerBase ) : 
			base( node, mixerBase ) { }
		
		public override void OnComplete()
		{
			FMT.Matrix.ResetIdentity();
			float str = 0.5f;
			Transform value = null;
			for (int i=0; i < Handles.Count; ++i)
			{
				var v = Handles[i];
				if (v.HasValue && v.Strength > str)
				{
					value = v.Value;
					str = v.Strength;
				}
			}
			
			if (value != null)
				value.AppendTo( FMT.Matrix );
				
			FMT.Changed();
		}
	}
}
