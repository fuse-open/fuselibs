using Uno;
using Fuse;
using Fuse.Controls;

public partial class RotateAnimatorTest_00
{
	public RotateAnimatorTest_00()
	{
		InitializeUX();
	}

	public Rotation Rotation1
	{
		get
		{
			return FirstChild<Rotation>();
		}
	}
}
