using Uno;

namespace Fuse.Motion.Simulation
{
	interface Simulation
	{
		/**
			@return true if the simulation is stable (no movement happens in Update). For clarity, user movement
				*is* considered static (since Update won't do anything until the user movement stops).
		*/
		bool IsStatic { get; }
		
		/**
			Steps the indicated time.
		*/
		void Update( double elapsed );
	}
	
	interface MotionSimulation<T> : Simulation
	{
		T Position { get; set; }
		T Velocity { get; set; }
	}
	
	interface DestinationSimulation<T> : MotionSimulation<T>
	{
		T Destination { get; set; }
		
		void Reset( T destination );
		/**
			Indicates that a new motion sequence is starting. Some simulations may respond
			differntly to this than just modifying the destination alone.
		*/
		void Start();
	}
	
}
