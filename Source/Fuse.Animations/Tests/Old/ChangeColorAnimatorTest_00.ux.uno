using Uno;
using Fuse;
using Fuse.Controls;

public partial class ChangeColorAnimatorTest_00
{
	public ChangeColorAnimatorTest_00()
	{
		InitializeUX();
	}

	public float4 Color1
	{
		get
		{
			return panel1Color.Color;
		}
	}
}

