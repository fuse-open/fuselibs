using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Animations;

namespace Fuse.Triggers
{
	public abstract class WhileEnabledDisabledTrigger : WhileTrigger
	{
		internal WhileEnabledDisabledTrigger() { }

		abstract protected bool IsActive { get; }

		protected override void OnRooted()
		{
			base.OnRooted();
			Parent.IsContextEnabledChanged += OnIsContextEnabledChanged;

			SetActive(IsActive);
		}

		protected override void OnUnrooted()
		{
			Parent.IsContextEnabledChanged -= OnIsContextEnabledChanged;
			base.OnUnrooted();
		}

		void OnIsContextEnabledChanged(object sender, EventArgs args)
		{
			SetActive(IsActive);
		}
	}

	/**
		Active while the `IsEnabled` property of its containing element is `False`.

		@examples Docs/WhileEnabledDisabled.md
	*/
	public class WhileDisabled : WhileEnabledDisabledTrigger
	{
		protected override bool IsActive
		{
			get
			{
				return Parent != null ? !Parent.IsContextEnabled : false;
			}
		}
	}

	/**
		Active while the `IsEnabled` property of its containing element is `True`.

		# Example
		This example shows a panel that is rotated 45 degrees. It will always be rotated 45 degrees, as `IsEnabled` is `true` by default.

			<Panel  Width="50" Height="50" Background="Red" >
				<WhileEnabled>
					<Rotate Degrees="45" Duration="0.5"/>
				</WhileEnabled>
			</Panel>

		@examples Docs/WhileEnabledDisabled.md
	*/
	public class WhileEnabled : WhileEnabledDisabledTrigger
	{
		protected override bool IsActive
		{
			get
			{
				return Parent != null ? Parent.IsContextEnabled : true;
			}
		}
	}

}
