using Uno;

namespace Fuse.Triggers.Actions
{
	public interface IShow
	{
		void Show();
	}

	/** Makes an @Element visible by setting `Visibility` to `Visible`.
	
		## Basic syntax
		
			<Show TargetNode="myElement" />
		
		## Example
			
			<Grid RowCount="3" ColumnCount="1">
				<Button Text="Show the elements">
					<Clicked>
						<Show TargetNode="hiddenElement" />
						<Show TargetNode="collapsedElement" />
					</Clicked>
				</Button>
				
				<Panel ux:Name="hiddenElement" Visibility="Hidden" Background="Blue" />
				<Panel ux:Name="collapsedElement" Visibility="Collapsed" Background="Red" />
			</Grid>
	*/
	public class Show: TriggerAction
	{
		protected override void Perform(Node target)
		{
			var t = target.FindByType<IShow>();
			if (t != null) 
				t.Show();
			else
				Fuse.Diagnostics.UserError( "Cannot find an Element/IShow", this );
		}
	}

	public interface IHide
	{
		void Hide();
	}

	/** Hides an @Element by setting `Visibility` to `Hidden`.
	
		When an element is hidden, it will not be drawn, but still take up space in the layout.
		Use @Collapse if you don't want the element to take up any space.
	
		## Basic syntax
		
			<Hide TargetNode="myElement" />
		
		## Example
			
			<Button Text="Hide the element">
				<Clicked>
					<Hide TargetNode="visibleElement" />
				</Clicked>
			</Button>
			
			<Panel ux:Name="visibleElement" Visibility="Visible" Background="Blue" />
	*/
	public class Hide: TriggerAction
	{
		protected override void Perform(Node target)
		{
			var t = target.FindByType<IHide>();
			if (t != null) 
				t.Hide();
			else
				Fuse.Diagnostics.UserError( "Cannot find an Element/IHide", this );
		}
	}

	public interface ICollapse
	{
		void Collapse();
	}

	/** Collapses an @Element by setting `Visibilty` to `Collapsed`.
		
		When an element is collapsed, it won't take up any space in the layout.
		Use @Hide if you want the element to be invisible, but still take up space.
		
		## Basic syntax
		
			<Collapse TargetNode="myElement" />
		
		## Example
			
			<Button Text="Collapse the element">
				<Clicked>
					<Collapse TargetNode="visibleElement" />
				</Clicked>
			</Button>
			
			<Panel ux:Name="visibleElement" Visibility="Visible" Background="Blue" />
	*/
	public class Collapse: TriggerAction
	{
		protected override void Perform(Node target)
		{
			var t = target.FindByType<ICollapse>();
			if (t != null) 
				t.Collapse();
			else
				Fuse.Diagnostics.UserError( "Cannot find an Element/ICollapse", this );
		}
	}
}
