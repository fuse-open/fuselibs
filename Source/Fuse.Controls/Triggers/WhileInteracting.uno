using Uno;

using Fuse.Elements;

namespace Fuse.Triggers
{
	/**
		Active while the user is interacting with the surrounding element.

		`WhileInteracting` is active in a @SwipeGesture while the user is swiping, and in a @ScrollView when the user is scrolling.

		## Example

		The following example shows a @Panel whose background color changes when the user is interacting with the @ScrollView surrounding it:

			<ScrollView Alignment="VerticalCenter" ClipToBounds="False">
				<Panel ux:Name="coloredPanel" Background="#f00" HitTestMode="LocalBoundsAndChildren" MinHeight="200">
					<Text Alignment="Center" TextColor="#fff">Scroll me!</Text>
				</Panel>

				<WhileInteracting>
					<Change coloredPanel.Background="#00f" />
				</WhileInteracting>
			</ScrollView>
	*/
	public class WhileInteracting : WhileTrigger
	{
		Visual _source;
		/** Overrides the element that `WhileInteracting` will respond to.

			If not explicitly specified, this corresponds to the first relevant parent element in the visual hierarchy.
		*/
		public Visual Source
		{
			get { return _source; }
			set { _source = value; }
		}
		
		Visual _visual;
		protected override void OnRooted()
		{
			base.OnRooted();

			_visual = _source ?? Parent;
			_visual.IsInteractingChanged += OnInteractingChanged;
			SetActive(_visual.IsInteracting);
		}

		protected override void OnUnrooted()
		{
			_visual.IsInteractingChanged -= OnInteractingChanged;
			_visual = null;
			base.OnUnrooted();
		}

		void OnInteractingChanged(object s, object a)
		{
			SetActive(_visual.IsInteracting);
		}
	}

	/**
		Triggers when an interaction completes.

		`InteractionCompleted` indicates the user is done interacting with an
		element, and is a counterpart to @WhileInteracting.

		## Example

		The following example shows a blue panel with a slider on it. When
		finishing a slide of the slider, the panel blinks red.

			<Panel ux:Name="panel" Color="Blue">
				<Slider >
					<InteractionCompleted>
						<Change DurationBack="0.5" panel.Color="Red"/>
					</InteractionCompleted>
				</Slider>
			</Panel>
	*/
	public class InteractionCompleted : Trigger
	{
		Visual _source;
		/**
			The element being interacted with.

			If not set, the parent element is used instead.
		*/
		public Visual Source
		{
			get { return _source; }
			set { _source = value; }
		}
		
		Visual _visual;
		bool _on;
		protected override void OnRooted()
		{
			base.OnRooted();

			_visual = _source ?? Parent;
			_visual.IsInteractingChanged += OnInteractingChanged;
			_on = _visual.IsInteracting;
		}

		protected override void OnUnrooted()
		{
			_visual.IsInteractingChanged -= OnInteractingChanged;
			_visual = null;
			base.OnUnrooted();
		}

		void OnInteractingChanged(object s, object a)
		{
			bool n = _visual.IsInteracting;
			if (n == _on)	
				return;
			_on = n;
			
			if (!n)
				Pulse();
		}
	}
}
