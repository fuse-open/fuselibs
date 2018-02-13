using Uno;
using Uno.UX;
using Fuse.Triggers.Actions;
using Fuse.Animations;

namespace Fuse.Triggers
{
	public abstract class WhileBool : WhileValue<bool>, IToggleable
	{
		public new bool Value
		{
			get { return base.Value; }
			set { base.Value = value; }
		}

		public void Toggle()
		{
			Value = !Value;
		}
	}

	/**
		A trigger that is active while its `Value` property is `true`.
		
		## Examples
		
		By default, the value of a `WhileTrue` is `false`.
		
			<WhileTrue>
				<!-- Any actions/animators placed here will never be triggered -->
			</WhileTrue>
		
		You can, however, use @Set to change its value.
		
			<Panel Width="200" Height="200" Background="#000">
				<Clicked>
					<Set moveToTheRight.Value="true" />
				</Clicked>
			
				<WhileTrue ux:Name="moveToTheRight">
					<Move X="200" Duration="0.4" />
				</WhileTrue>
			</Panel>
		
		Its value can also be toggled on and off using @Toggle.
		
			<Panel Width="200" Height="200" Background="#000">
				<WhileTrue ux:Name="moveToTheRight">
					<Move X="200" Duration="0.4" />
				</WhileTrue>
				
				<Clicked>
					<Toggle Target="moveToTheRight" />
				</Clicked>
			</Panel>
		
		It is also particularly useful to data-bind `Value` to an @Observable.

		The following example consists of a @TextBox, as well as a @Button that fades to full transparency while
		the user has entered less than 6 characters into the @TextBox.

			<JavaScript>
				var Observable = require("FuseJS/Observable");
				
				var password = Observable("");
				var isPasswordInvalid = password.map(function(value) {
					return value.length < 6;
				});
				
				module.exports = {
					password: password,
					isPasswordInvalid: isPasswordInvalid
				};
			</JavaScript>

			<StackPanel Alignment="VerticalCenter" ItemSpacing="50" Margin="50">
				<TextBox Value="{password}" IsPassword="true" />
				<Button Text="Log in" ux:Name="loginButton" />
				
				<WhileTrue Value="{isPasswordInvalid}">
					<Change loginButton.Opacity="0" Duration="0.3" />
				</WhileTrue>
			</StackPanel>
			
		## Instance
		
		The children of `WhileTrue` are created whether the `Value` is true or false; this is the standard behavior of all triggers. If you need to prevent item creation when the value is false, consider using an `Instance` instead and bind to the `IsEnabled` property.
	*/
	public class WhileTrue : WhileBool
	{
		protected override bool IsOn { get { return Value; } }
	}
	
	/**
		A trigger that is active while its `Value` property is `false`.
		
		> *Note*
		>
		> This is the exact opposite from @WhileTrue.
		> Head over there for documentation and examples.
	*/
	public class WhileFalse : WhileBool
	{
		protected override bool IsOn { get { return !Value; } }
	}
}
