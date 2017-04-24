using Uno;
using Uno.Collections;
using Fuse;

namespace Fuse.Animations
{
	class AverageMixer : MixerBase
	{
		protected override MasterProperty<T> CreateMaster<T>( Uno.UX.Property<T> property,
			MixerBase mixerBase)
		{ return new AverageMasterProperty<T>(property, mixerBase); }
		protected override MasterBase<Transform> CreateMasterTransform( Visual element,
			MixerBase mixerBase)
		{ return new AverageMasterTransform(element, mixerBase); }
	}
	
	class AverageMasterProperty<T> : MasterProperty<T>
	{
		public AverageMasterProperty( Uno.UX.Property<T> property, MixerBase mixerBase ) : 
			base(property, mixerBase) { }
		
		protected Internal.Blender<T> blender;
		protected override void OnActive() 
		{
			base.OnActive();
			if (blender == null)
				blender = Internal.BlenderMap.Get<T>();
		}
		
		public override void OnComplete()
		{
			var weight = GetFullWeight();
				
			T nv = blender.Weight( RestValue, weight.Rest / weight.Full );
			var c = Handles.Count;
			for (int i=0; i < c; ++i)
			{
				var v = Handles[i];
				if (!v.HasValue)
					continue;
					
				T add;
				if (v.MixOp == MixOp.Weight)
					add = blender.Weight( v.Value, Math.Max(0,v.Strength) / weight.Full );
				else if (v.MixOp == MixOp.Offset)
					add = blender.Weight( blender.Sub( v.Value, RestValue ), v.Strength );
				else
					add = blender.Weight( v.Value, v.Strength );

				nv = blender.Add( nv, add );
			}

			Set(nv);
		}
	}
	
	class AverageMasterTransform : MasterTransform
	{
		public AverageMasterTransform( Visual node, MixerBase mixerBase ) : 
			base( node, mixerBase ) { }
		
		public override void OnComplete()
		{
			var weight = GetFullWeight();
			
			FastMatrix nv = FastMatrix.Identity();
			
			var c = Handles.Count;
			for (int i=0; i < c; ++i)
			{
				var v = Handles[i];
				if (!v.HasValue)
					continue;
					
				if (v.MixOp == MixOp.Weight)
					v.Value.AppendTo( nv, v.Strength / weight.Full );
				else
					v.Value.AppendTo( nv, v.Strength );
			}

			if (!nv.Matrix.Equals(FMT.Matrix.Matrix))
			{
				FMT.Matrix = nv;
				FMT.Changed();
			}
		}
	}
}
