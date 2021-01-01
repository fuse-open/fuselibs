using Uno;

using Fuse.Triggers;

namespace Fuse.Navigation
{
	/**
		Is active while a page, optionally matching given criteria, is active in the navigation.

		This trigger checks the `Navigation.Active` page only. During a transition it will consider partial progress, but only for the `Active` page itself.
	*/
	public class WhilePageActive : WhileTrigger
	{
		INavigation _navigation;

		float _threshold = 1;
		/**
			At which progress should this trigger become active.

			The default is `1`, meaning the trigger will only become active when the page is fully reaches the matching state; partial page progress will be ignored.
		*/
		public float Threshold
		{
			get { return _threshold; }
			set { _threshold = value; }
		}

		float _limit;
		bool _hasLimit;
		/**
			An optional limit for when the trigger is active. A progress past this limit will deactivate the trigger.
		*/
		public float Limit
		{
			get { return _limit; }
			set
			{
				_limit = value;
				_hasLimit = true;
			}
		}

		string _nameEquals;
		/**
			If non-null then the name of the page must equal this value for the trigger to be active.

			In a `Navigator` the `path` of a `Route` becomes the `Name` allowing this property to be used for path matching.
		*/
		public string NameEquals
		{
			get { return _nameEquals; }
			set { _nameEquals = value; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_navigation = Navigation.TryFind(Parent);
			if (_navigation == null)
			{
				Fuse.Diagnostics.UserError( "Must be used within a navigation context", this );
				return;
			}

			_navigation.PageProgressChanged += OnStateChanged;
			Update();
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if (_navigation != null)
			{
				_navigation.PageProgressChanged -= OnStateChanged;
				_navigation = null;
			}
		}

		void OnStateChanged(object sender, NavigationArgs args)
		{
			Update();
		}

		void Update()
		{
			var active = _navigation.ActivePage;
			if (active == null)
			{
				SetActive(false);
				return;
			}

			var progress = 1 - Math.Abs(_navigation.GetPageState(active).Progress);
			var set = progress >= Threshold;
			if (_hasLimit)
				set = set && progress <= Limit;

			if (NameEquals != null)
				set = set && ((string)active.Name == NameEquals);

			SetActive( set );
		}
	}
}