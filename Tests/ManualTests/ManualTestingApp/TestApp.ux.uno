using Uno;

using Fuse;

public partial class TestApp
{
	public TestApp()
	{
		InitializeUX();
	
		TheVersion.Value = String.Format("Build {0}", Version.VersionString);
	}
}
