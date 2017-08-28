using Uno;
using Uno.Collections;

namespace Fuse
{
	public abstract partial class Visual
	{
		struct InteractionItem
		{
			public object Id;
			public Action Cancelled;
		}
		Dictionary<object,InteractionItem> _interactions;
		
		/** Raised when the `IsInteracting` property changes.
			@advanced */
		public event EventHandler IsInteractingChanged;
		public bool IsInteracting
		{
			get { return _interactions != null && _interactions.Count > 0; }
		}
		
		/**
			@param id identifier of the interaction
			@param cancelled will be called if the interaction is cancelled
		*/
		public void BeginInteraction(object id, Action cancelled)
		{
			if (_interactions == null)
				_interactions = new Dictionary<object,InteractionItem>();
				
			_interactions[id] = new InteractionItem{ Id = id, Cancelled = cancelled };
			OnInteractionsChanged();
		}
		
		public void EndInteraction(object id)
		{
			if (_interactions == null)
				return;
				
			_interactions.Remove(id);
			if (_interactions.Count == 0)
				_interactions = null;
				
			OnInteractionsChanged();
		}
		
		void OnInteractionsChanged()
		{
			if (IsInteractingChanged != null)
				IsInteractingChanged(this, EventArgs.Empty);
		}
		
		public enum CancelInteractionsType
		{
			Local,
			Recursive
		}
		public void CancelInteractions(CancelInteractionsType how = CancelInteractionsType.Recursive)
		{
			if (_interactions != null)
			{
				//dup list of ids since EndInteraction will be called during cancelling
				var ids = new List<object>();
				foreach (var i in _interactions)
					ids.Add(i.Key);
					
				foreach (var id in ids)
				{
					if (_interactions.ContainsKey(id))
					{
						var i = _interactions[id];
						i.Cancelled();
					}
				}
			}
			
			if (how == CancelInteractionsType.Recursive)
			{
				for (var v = FirstChild<Visual>(); v != null; v = NextSibling<Visual>())
					v.CancelInteractions(how);
			}
		}
	}
}
