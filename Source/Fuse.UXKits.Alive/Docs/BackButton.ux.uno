namespace Alive
{
	/**
		A left-pointing arrow, used in navigation.
		**Note:** this component only provides visuals and does not actually perform navigation.
		
			<Router ux:Name="router" />
		
			<JavaScript>
				exports.goBack = function() {
					router.goBack();
				}
			}
			</JavaScript>
		
			<Alive.BackButton Clicked="{goBack}" />
	*/
	public partial class BackButton {}
}
