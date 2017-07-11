using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse;

namespace Fuse.Animations
{
	/**
		Specifies how animation values are combined with the target rest value to create new values.
	*/
	public enum MixOp
	{
		/** The difference between the value and rest value is added to the current value */
		Offset,
		/** The value is added to the current value */
		Add,
		/** A weighted average of all applied `Weight` values, and rest value, is taken. */
		Weight,
	}

	public interface IMixer
	{
		IMixerHandle<T> Register<T>( Uno.UX.Property<T> property, MixOp mode );
		IMixerHandle<Transform> RegisterTransform( Visual element, MixOp mode, int priority = 0 );
	}
	
	public interface IMixerHandle<T>
	{
		void Unregister();
		void Set(T value, float strength);
		T RestValue { get; }
	}
	
	class Mixer
	{
		static IMixer _default = new AverageMixer();
		static public IMixer Default { get { return _default; } }
		static IMixer _defaultDiscrete = new DiscreteMixer();
		static public IMixer DefaultDiscrete { get { return _defaultDiscrete; } }
	}
	
	interface IMixerMaster {}
	
	abstract class MixerBase : IMixer
	{
		Dictionary<object,object> Masters = new Dictionary<object,object>();
		
		public IMixerHandle<T> Register<T>( Uno.UX.Property<T> property, MixOp mode )
		{
			object master;
			if (!Masters.TryGetValue(property, out master))
			{
				master = CreateMaster<T>(property, this);
				Masters.Add(property, master);
			}
			
			var masterT = (MasterBase<T>)master;
			return new MixerHandle<T>(masterT, mode, 0);
		}

		PropertyHandle _propHandle = Fuse.Properties.CreateHandle();
		public IMixerHandle<Transform> RegisterTransform( Visual element, MixOp mode, int priority = 0 )
		{
			object master;
			if (!element.Properties.TryGet(_propHandle, out master))
			{
				master = CreateMasterTransform(element, this);
				element.Properties.Set(_propHandle, master);
			}
			
			var masterT = (MasterBase<Transform>)master;
			return new MixerHandle<Transform>(masterT, mode, priority);
		}
		
		//these is needed to release the memory from Masters once nothing more needs
		//the master (primarily for the Property case, since Transforms are using attached properties)
		public void Unused(IMixerMaster mb)
		{
			var prop = mb as MasterPropertyGet;
			if (prop != null)
				Masters.Remove(prop.GetPropertyObject());
				
			var trans = mb as MasterTransform;
			if (trans != null)
				trans.Visual.Properties.Clear(_propHandle);
		}
		
		abstract protected MasterProperty<T> CreateMaster<T>( Uno.UX.Property<T> property,
			MixerBase mixerBase);
		abstract protected MasterBase<Transform> CreateMasterTransform( Visual element,
			MixerBase mixerBase);
	}
	
	abstract class MasterBase<T> : IMixerMaster
	{
		MixerBase _mixerBase;
		protected MasterBase( MixerBase mixerBase = null )
		{
			_mixerBase = mixerBase;
		}
		
		~MasterBase()
		{
		/*	if (defined(DEBUG))
			{
				if (Handles.Count != 0)
					debug_log "MasterBase still has handles: " + GetHashCode();
			}*/
		}
		
		bool _inactive;
		protected List<MixerHandle<T>> Handles = new List<MixerHandle<T>>();
		public void Register(MixerHandle<T> handle)
		{
			if (_inactive)
			{
				Fuse.Diagnostics.InternalError( "Attempt to register in inactive Master", this);
				return;
			}
			
			int at=0;
			for (; at < Handles.Count && handle.Priority <= Handles[at].Priority; ++at);
			Handles.Insert(at,handle);
			
			if (Handles.Count == 1)
				OnActive();
		}
		
		public void Unregister(MixerHandle<T> handle)
		{
			Handles.Remove(handle);
			MarkDirty();
			
			if (Handles.Count == 0)
			{
				_inactive = true;
				OnInactive();
				if (_mixerBase != null)
					_mixerBase.Unused(this);
			}
		}
		
		virtual protected bool PostLayout { get { return false; } }
		
		virtual protected void OnActive() { }
		abstract protected void OnInactive();

		void Complete()
		{
			//can happen if handles unregistered while deferred action is pending
			if (!DirtyValue)
				return;
				
			DirtyValue = false;
			//RestValue should be set during OnInactive
			if (Handles.Count == 0)
				return;
				
			OnComplete();
		}
		
		public void MarkDirty()
		{
			if (DirtyValue)
				return;
				
			DirtyValue = true;
			if (Handles.Count < 2)
			{
				Complete();
				return;
			}
			
			UpdateManager.AddDeferredAction(Complete);
		}
			
		protected struct GFWResult
		{
			public float Rest;
			public float Full;
		}
			
		protected GFWResult GetFullWeight()
		{
			float fullWeight = 0;
			var c = Handles.Count;
			for (int i=0; i < c; ++i)
			{
				var v = Handles[i];
				if (v.MixOp == MixOp.Weight)
					fullWeight += v.HasValue ? Math.Max(0,v.Strength) : 0; //negative weight isn't valid
			}
			
			//anything less than 1 is averaged with RestValue
			float restWeight = 1 - Math.Min(fullWeight,1);
			fullWeight = Math.Max(1,fullWeight);
			return new GFWResult{ Rest = restWeight, Full = fullWeight };
		}
		
		internal bool DirtyValue;
		
		abstract public T RestValue { get; }
		abstract public void OnComplete();
	}
	
	interface MasterPropertyGet
	{
		object GetPropertyObject();
	}
	abstract class MasterProperty<T> : MasterBase<T>, MasterPropertyGet, IPropertyListener
	{
		internal Uno.UX.Property<T> Property;
		public object GetPropertyObject() { return Property; }
		
		protected MasterProperty( Uno.UX.Property<T> property, MixerBase mixerBase )
			: base(mixerBase)
		{
			Property = property;
		}
		
		T _restValue;
		public override T RestValue
		{	
			get
			{
				return _restValue;
			}
		}

		bool _isListening;
		protected override void OnActive()
		{
			if (!_isListening)
			{
				_restValue = Property.Get();
				Property.AddListener(this);
				_isListening = true;
			}
		}
		
		protected override void OnInactive()
		{
			if (_isListening)
			{
				Property.RemoveListener( this );
				Property.Set( RestValue, this );
				_isListening = false;
			}
		}
		
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector property)
		{
			if (Property.Name != property) return;

			var v = Property.Get();

			if (Property.SupportsOriginSetter)
			{
				_restValue = v;
			}
			else if (!_hasSetValue || !_lastSetValue.Equals(v))
			{
				GiveOriginSetterWarning();
				_restValue = v;
			}
		}

		bool _warningGiven;
		void GiveOriginSetterWarning()
		{
			if (!_warningGiven)
			{
				_warningGiven = true;
				Fuse.Diagnostics.UserWarning("The property " + Property.Name + " of " + Property.Object 
					+ " cannot be reliably animated because it does not provide an origin-setter. Animating this property may lead to visual glitches or inconsistencies.", this);
			}
		}

		bool _hasSetValue;
		T _lastSetValue;
		protected void Set(T value)
		{
			if (!_isListening) throw new Exception();

			_hasSetValue = true;
			_lastSetValue = value;
			Property.Set(value, this);
		}
	}

	sealed class FastMatrixTransform : Transform
	{
		public FastMatrix Matrix = FastMatrix.Identity();
		
		public override void AppendTo(FastMatrix m, float weight)
		{
			//ignore weight (impl would require impossible generic Matrix power)
			m.AppendFastMatrix(Matrix);
		}
		
		public override void PrependTo(FastMatrix m)
		{
			m.PrependFastMatrix(Matrix);
		}
		
		public void Changed()
		{
			OnMatrixChanged();
		}
		
		public override bool IsFlat
		{
			get 
			{
				var m = Matrix.Matrix;
				const float zeroTolerance = 1e-05f;
				var q = Math.Abs(m.M13) < zeroTolerance &&
					Math.Abs(m.M23) < zeroTolerance &&
					Math.Abs(m.M43) < zeroTolerance &&
					Math.Abs(m.M14) < zeroTolerance &&
					Math.Abs(m.M24) < zeroTolerance &&
					Math.Abs(m.M34) < zeroTolerance;
				return q;
			}
		}
	}
	
	abstract class MasterTransform : MasterBase<Transform>
	{
		protected override bool PostLayout { get { return true; } }
		
		internal Visual Visual;
		protected MasterTransform( Visual node, MixerBase mixerBase ) :
			base( mixerBase )
		{
			Visual = node;
		}
		
		protected FastMatrixTransform FMT;
		protected override void OnActive() 
		{ 
			FMT = new FastMatrixTransform();
			Visual.Children.Add(FMT);
		}
		
		protected override void OnInactive() 
		{
			Visual.Children.Remove(FMT);
			FMT = null;
		}
		
		static Transform identity = new Translation();
		public override Transform RestValue
		{
			get { return identity; }
		}
	}
	
	class MixerHandle<T> : IMixerHandle<T>
	{
		public T Value;
		public float Strength;
		
		bool _hasValue;
		public bool HasValue { get { return _hasValue; } }
		
		public MixOp MixOp { get; set; }
		
		public int Priority { get; private set; }
		
		MasterBase<T> Master;
		public MixerHandle( MasterBase<T> master, MixOp mode, int priority )
		{
			Priority = priority;
			Master = master;
			MixOp = mode;
			Master.Register(this);
		}
		
		public void Unregister()
		{
			_hasValue = false;
			Master.Unregister(this);
			Master = null;
		}
		
		public void Set(T value, float strength)
		{
			if (Master == null)
			{	
				debug_log "invalid MixerHandle.Set post-Unregister";
				return;
			}
			
			_hasValue = true;
			this.Value = value;
			this.Strength = strength;
			Master.MarkDirty();
		}
		
		public T RestValue 
		{ 
			get 
			{ 
				if (Master == null)
					throw new Exception("Invalid MixerHandle.RestValue post-Unregister");
				return Master.RestValue; 
			} 
		}
	}
}
