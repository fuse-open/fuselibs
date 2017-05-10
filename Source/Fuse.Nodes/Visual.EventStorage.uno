using Uno;

namespace Fuse
{
	public partial class Visual
	{
		// Optimized storage for events and low-level node properties
		// Basically everything is stored in this bit field:
		// In the rare case where an event actually has listeners, extrinsic lists are used
		// to store the list of listeners.
		int _nodebits;

		enum VisualBits
		{
			Styled,
			Resources,
			ResourceChanged,
			Style,
			IsContextEnabledChanged,
			IsVisibleChanged,
			Added,
			Removed,
			Rooted,
			Unrooted,
			WorldTransformInvalidated,
			ParameterChanged,
		}

		bool HasBit(VisualBits nb) { return (_nodebits & (1<<(int)nb)) != 0; }
		void SetBit(VisualBits nb) { _nodebits |= (1<<nb); }
		void ClearBit(VisualBits nb) { _nodebits &= ~(1<<nb); }

		void RaiseEvent(PropertyHandle ph, VisualBits ne)
		{
			if (HasBit(ne)) Properties.ForeachInList(ph, InvokeEventHandler, EventArgs.Empty);
		}

		void InvokeEventHandler(object obj, object args) 
		{ 
			((EventHandler)obj)(this, (EventArgs)args);
		}
		

		void AddEventHandler(PropertyHandle ph, VisualBits ne, object handler)
		{
			Properties.AddToList(ph, handler);
			SetBit(ne);
		}

		void RemoveEventHandler(PropertyHandle ph, VisualBits ne, object handler)
		{
			Properties.RemoveFromList(ph, handler);

			object foo;
			if (!Properties.TryGet(ph, out foo)) ClearBit(ne);
		}

	}
}