namespace Fuse.Animations
{
	/**
		@deprecated there is no way to use this correctly
	*/
	public class PropertyModifier<T>
	{
		public Property<T> Target { get; set; }
		public IMixer Mixer { get; set; }
		
		float _strength = 1;
		public float Strength 
		{ 
			get { return _strength; }
			set 
			{ 
				_strength = value; 
				Update();
			}
		}
		
		IMixerHandle<T> _mixHandle;
		
		bool _hasValue;
		T _value;
		public float Value
		{
			get { return _value; }
			set
			{
				_hasValue = true;
				_value = value;
				Update();
			}
		}
		
		void Update()
		{
			if (!_hasValue)
				return;
				
			if (_mixHandle == null)
				_mixHandle = Mixer.Register( Target );
			
			_mixHandle.Set( Value, Strength );
		}
		
		void Clear()
		{
			_mixHandle.Unregister();
		}
	}
}
