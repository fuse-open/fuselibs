using Fuse;
using Fuse.Controls;
using Fuse.Elements;

using Uno.Diagnostics;

class TestRunner : ContentControl
{
	int _testIndex;

	void StartTest(int testIndex)
	{
		var template = Templates[testIndex];
		_testIndex = testIndex;

		var test = (Element)template.New();
		var testName = test.Name != null ? test.Name.ToString() : "<Unnamed>";
		Debug.Log("Starting test: " + testName);
		Content = test;
	}

	void StopTest()
	{
		Content = null;
		Uno.Runtime.Implementation.Internal.Unsafe.Quit();
	}

	protected override void OnRooted()
	{
		base.OnRooted();
		if (Templates.Count > 0)
			StartTest(0);
	}

	protected override void OnUnrooted()
	{
		base.OnUnrooted();
	}

	public void OnTestFinished()
	{
		if (Templates.Count > _testIndex + 1)
			StartTest(_testIndex + 1);
		else
			StopTest();
	}
}
