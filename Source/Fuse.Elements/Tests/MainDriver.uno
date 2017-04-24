using Fuse;
using FuseTest;

//temporary solution to enable debugging of tests
public class TestApp : Uno.Application
{
	public TestApp()
	{	
		(new CachingTest()).SubpixelCaching();
	}
}
