using Uno;
using Fuse.Scripting;

namespace Fuse.Physics
{
	public abstract class ForceFieldTrigger: Fuse.Triggers.Trigger
	{
		public ForceField ForceField { get; set; }

		internal static void SetForce(ForceField field, Body body, float force)
		{
			for (var fft = body.Visual.FirstChild<ForceFieldTrigger>(); fft != null; fft = fft.NextSibling<ForceFieldTrigger>())
			{
				if (fft.ForceField == field)
					fft.SetForce(body, force);
			}
		}

		internal abstract void SetForce(Body n, float force);
	}

	public class ForceFieldEventArgs : EventArgs
	{
		internal Body Body { get; private set; }
		internal ForceField ForceField { get; private set; }

		public Visual Visual { get { return Body.Visual; } }

		internal ForceFieldEventArgs(Body body, ForceField field)
		{
			Body = body;
			ForceField = field;
		}
	}

	public delegate void ForceFieldEventHandler(object sender, ForceFieldEventArgs args);

	public abstract class ForceFieldEventTrigger: ForceFieldTrigger
	{
		public event ForceFieldEventHandler Handler;

		internal void OnTriggered(Body body)
		{
			Pulse();
			if (Handler != null)
			{
				var args = new ForceFieldEventArgs(body, ForceField);
				Handler(this, args);
			}
		}
	}
	/**
		Triggers as a draggable element enters the force field.

		As it is a pulse trigger, the forward animation will play in one continous run when the trigger is activated, and play the backwards animation continously when deactivated.

		## Example
		In the following example, a circle in the middle of the screen flashes green if a smaller, blue circle, is moved into its force field:

			<Panel>
				<Panel Width="60" Height="60" Alignment="BottomLeft">
					<Circle Color="#42A5F5" />
					<Draggable />
					<EnteredForceField ForceField="centerAttract">
						<Change centerCircle.Color="#66BB6A" Duration=".5"/>
					</EnteredForceField>
				</Panel>
				<Panel Width="200" Height="200" Alignment="Center" >
					<Circle ux:Name="centerCircle" Color="#EF5350" />
					<PointAttractor ux:Name="centerAttract" Radius="150" Strength="250" />
				</Panel>
			</Panel>
			<Panel Alignment="BottomLeft" Width="100" Height="100">
				<PointAttractor Radius="500" Strength="100" Offset="0,0,0"/>
			</Panel>
	*/
	public class EnteredForceField: ForceFieldEventTrigger
	{
		public float Threshold { get; set; }

		float _oldForce;

		internal override void SetForce(Body body, float force)
		{
			if (_oldForce <= Threshold && force > Threshold) OnTriggered(body);
			_oldForce = force;
		}
	}

	/**
		@mount Physics

		Triggers as a draggable element leaves the force field.

		As it is a pulse trigger, the forward animation will play in one continous run when the trigger is activated, and play the backwards animation continously when deactivated.

		## Example
		In the following example, a circle with a `PointAttractor` in the middle of the screen flashes green if a smaller, blue circle, is removed from the forcefield.

			<Panel>
				<Panel Width="60" Height="60" Alignment="Center">
					<Circle Color="#42A5F5" />
					<Draggable />
					<ExitedForceField ForceField="centerAttract">
						<Change centerCircle.Color="#66BB6A" Duration=".5"/>
					</ExitedForceField>
				</Panel>
				<Panel Width="200" Height="200" Alignment="Center" >
					<Circle ux:Name="centerCircle" Color="#EF5350" />
					<PointAttractor ux:Name="centerAttract" Radius="150" Strength="250" />
				</Panel>
			</Panel>
	*/
	public class ExitedForceField: ForceFieldEventTrigger
	{
		public float Threshold { get; set; }

		float _oldForce;

		internal override void SetForce(Body body, float force)
		{
			if (_oldForce > Threshold && force <= Threshold) OnTriggered(body);
			_oldForce = force;
		}
	}

	/**
		@mount Physics
		
		Animates a draggable element depending on how close it is to a point attractor

		The animation will animate from 0(outside the forcefield radius), to 1(at the center of the forcefield), unless `From` and `To` are used to specify a custom range. This is the same as using a `RangeAdapter`.

		# Example
		In the following example, a red circle will get smaller as a blue, filled circle nears the center `PointAttract`, `centerAttract`. Because `To` is set to `1.3` on the `InForceFieldAnimation`, the animation will never animate further than `0.77`.

			<Panel>
				<Panel Width="60" Height="60" Alignment="BottomLeft">
					<Circle Color="#42A5F5" />
					<Draggable />
					<InForceFieldAnimation  ForceField="centerAttract" From="0" To="1.3">
						<Scale Target="centerCircle" Factor=".0" />
					</InForceFieldAnimation>
				</Panel>
				<Panel Width="300" Height="300" Alignment="Center" >
					<Circle ux:Name="centerCircle" >
						<Stroke Color="#F00" Width="4"/>
					</Circle>
					<PointAttractor ux:Name="centerAttract" Radius="150" Strength="250" />
				</Panel>
			</Panel>
			<Panel Alignment="BottomLeft" Width="100" Height="100">
				<PointAttractor Radius="300" Strength="150" Offset="0,0,0"/>
			</Panel>
	*/
	public class InForceFieldAnimation : ForceFieldTrigger
	{
		/**
			When the animation starts
		*/
		public float From { get; set; }
		/**
			When the animation ends
		*/
		public float To { get; set; }

		public InForceFieldAnimation()
		{
			From = 0;
			To = 1;
		}

		internal override void SetForce(Body body, float force)
		{
			var f = Math.Clamp((force - From) / (To-From), 0, 1);
			Seek(f, Fuse.Animations.AnimationVariant.Forward);	
		}
	}
}
