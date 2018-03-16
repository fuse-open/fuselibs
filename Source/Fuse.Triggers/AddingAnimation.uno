using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Animations;


namespace Fuse.Triggers
{
	interface IVisibility
	{
	}
	/**
		Triggers when the element is added to the visual tree.

		`AddingAnimation` is by default a backward animation, meaning it will
		animate from progress 1 back to 0.

		## Example

		The following example showcases a list that you can add elements to by
		pressing a button. Elements added are animated in using an
		`AddingAnimation`:

			<StackPanel Width="100%">
				<JavaScript>
					var Observable = require('FuseJS/Observable');
					var elements = Observable({value: "Element"});
					function addElement() {
						elements.add({value: "Element"});
					}
					module.exports = {elements, addElement};
				</JavaScript>
				<Each Items="{elements}">
					<Panel Width="100%" >
						<Text Value="{value}" Alignment="CenterLeft"/>
						<AddingAnimation>
							<Move RelativeTo="Size" Duration=".2" X="2" />
						</AddingAnimation>
					</Panel>
				</Each>
				<Button Text="Add more" Clicked="{addElement}"/>
			</StackPanel>
	*/
	public class AddingAnimation : Trigger
	{
		bool _delayFrame = true;
		public bool DelayFrame
		{
			get { return _delayFrame; }
			set { _delayFrame = value; }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			//https://github.com/fusetools/fuselibs-private/issues/1697
			//delay a frame to avoid first frame delay stutter
			BypassActivate();
			if (DelayFrame)
				UpdateManager.PerformNextFrame(DirectDeactivate);
			else
				DirectDeactivate();
		}
	}
}
