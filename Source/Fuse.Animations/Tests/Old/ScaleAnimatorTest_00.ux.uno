using Uno;
using Fuse;
using Fuse.Controls;

public partial class ScaleAnimatorTest_00
{
	public ScaleAnimatorTest_00()
	{
		InitializeUX();
	}

	public Scaling Scaling1
	{
		get
		{
			return FirstChild<Scaling>();
		}
	}
}
