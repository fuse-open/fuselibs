using Uno;
using Uno.UX;

using Fuse.Motion;
using Fuse.Reactive;
using Fuse.Motion.Simulation;

namespace Fuse.Animations
{
	/**
		A mixin-like class to provide common attractor behavior for variables inside Uno.
	*/
	class DestinationBehavior<T>
	{
		public DestinationMotionConfig Motion;
		
		public delegate void ValueHandler( T value );
		
		ValueHandler _handler;
		DestinationSimulation<T> _simulation;

		void OnUpdate()
		{
			if (_simulation == null) //safety
			{
				StopListenUpdate();
				return;
			}
				
			_simulation.Update( Time.FrameInterval );
			if (_handler != null)
				_handler( _simulation.Position );
			
			if (_simulation.IsStatic)
				StopListenUpdate();
		}
		
		bool _listenUpdate;
		void StopListenUpdate()
		{
			if (_listenUpdate)
			{
				UpdateManager.RemoveAction( OnUpdate );
				_listenUpdate = false;
			}
		}
		
		public void Unroot()
		{
			StopListenUpdate();
			_simulation = null;
			_handler = null;
		}
		
		public void SetValue( T value, ValueHandler handler )
		{
			if (Motion == null)
			{
				handler( value );
				return;
			}
			
			_handler = handler;
			if (_simulation == null)
			{
				_simulation = Motion.Create<T>();
				_simulation.Reset( value );
				//force in first frame to avoid unset initial values being rendered
				if (_handler != null)
					_handler( _simulation.Position );
			}
			else
			{
				_simulation.Destination = value;
				_simulation.Start();
			}
				
			if (!_listenUpdate)
			{
				UpdateManager.AddAction( OnUpdate );
				_listenUpdate = true;
			}
		}
	}
}
