using Uno;

using Fuse.Elements;
using Fuse.Input;

namespace Fuse.Gestures
{
	public class KeepInViewCommon : Behavior
	{
		internal KeepInViewCommon() {}

		Element _target;
		bool _attached;
		public Node Target
		{
			get { return _target; }
			set
			{
				var prev = _target;
				ReleaseElement();

				//TODO: we only can't use Node since it doesn't have an event saying it's placement
				//has been updated, but it does have a BringIntoView function.
				var v = value;
				while (v != null)
				{
					_target = v as Element;
					if (_target != null)
						break;
					v = v.Parent;
				}
				if (v == null)
				{
					//cancel pending request to stop request on undesirable node
					if (prev != null)
						prev.OnBringIntoView(null);
					_target = null;
				}
				else
				{
					AttachElement();
				}
			}
		}

		protected Element _rootElement;
		protected override void OnRooted()
		{
			base.OnRooted();

			_rootElement = Parent as Element;
			if (_rootElement != null)
			{
				_rootElement.Placed += Update;
				AttachElement();
			}
		}

		protected override void OnUnrooted()
		{
			if (_rootElement != null)
			{
				_rootElement.Placed -= Update;
				ReleaseElement();
			}

			base.OnUnrooted();
		}

		void ReleaseElement()
		{
			if (!_attached)
				return;

			_target.Placed -= Update;
			_attached = false;
		}

		void AttachElement()
		{
			if (_target == null)
				return;

			_target.Placed += Update;
			_attached = true;
			Update(null, null);
		}

		void Update(object s, object a)
		{
			if (_target != null)
				_target.BringIntoView();
		}
	}

	/**
		@mount Gestures
	*/
	public sealed class KeepInView : KeepInViewCommon
	{
	}

	/**
		@mount Gestures
	*/
	public sealed class KeepFocusInView : KeepInViewCommon
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Focus.Gained.AddHandler(Parent, OnGotFocus);
			Focus.Lost.AddHandler(Parent, OnLostFocus);
		}

		protected override void OnUnrooted()
		{
			Focus.Gained.RemoveHandler(Parent, OnGotFocus);
			Focus.Lost.RemoveHandler(Parent, OnLostFocus);
			base.OnUnrooted();
		}

		void OnGotFocus(object s, FocusGainedArgs fga)
		{
			Target = Focus.FocusedVisual; //may be null
		}

		void OnLostFocus(object s, object a)
		{
			Target = null;
		}
	}
}
