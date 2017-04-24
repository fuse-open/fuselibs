using Uno;
using Fuse;
using Fuse.Controls;

public partial class TranslateAnimatorTest_00
{
    public TranslateAnimatorTest_00()
    {
        InitializeUX();
    }

	public Translation Translation1
	{
		get
		{
			return FirstChild<Translation>();
		}
	}
}
