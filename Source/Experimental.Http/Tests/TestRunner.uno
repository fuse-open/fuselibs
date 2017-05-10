using Uno;
using Uno.Collections;
using Uno.Testing;
using Uno.Diagnostics;

public abstract class TestCase
{
	public abstract void Run();

	public virtual void Setup() {}
	public virtual void Teardown() { }
	
	internal TestRunner _runner;
	protected void Done()
	{
		_runner.DoneTestCase(this);
	}
}

public class TestRunner
{
	List<TestCase> _testCases = new List<TestCase>();
	
	public Action Done { get; set; }
	
	int _failCount;
	public int FailCount
	{
		get { return _failCount; }
	}
	
	public void Add( TestCase tc )
	{
		tc._runner = this;
		_testCases.Add(tc);
	}
	
	int _activeCaseIndex;
	TestCase _activeCase;
	double _activeStart;
	public void Run()
	{
		_activeCaseIndex = -1;
		NextCase();
	}
	
	void NextCase()
	{
		_activeCase = null;
		_activeCaseIndex++;
		if (_activeCaseIndex >= _testCases.Count)
		{
			Done();
			return;
		}
		
		_activeCase = _testCases[_activeCaseIndex];
		_activeStart = Clock.GetSeconds();
		
		try
		{
			debug_log "Running: " + _activeCase;
			_activeCase.Setup();
			_activeCase.Run();
		}
		catch( Exception e )
		{
			debug_log e;
			debug_log _activeCase + " : Exception";
			_failCount++;
			NextCase();
		}
	}
	
	internal void DoneTestCase( TestCase tc )
	{
		tc.Teardown();
		if (_activeCase == tc)
			NextCase();
	}
	
	public void CheckUpdate()
	{
		var elapsed = Clock.GetSeconds() - _activeStart;
		if (elapsed > 2)
		{
			debug_log _activeCase + " : Timeout";
			_failCount++;
			NextCase();
		}
	}
}

public class TestRunnerApp : Fuse.App
{
	protected TestRunner TestRunner = new TestRunner();
	
	public TestRunnerApp()
	{
		TestRunner.Done = Done;
	}

	void Done()
	{
		if (TestRunner.FailCount > 0)
		{
			debug_log "Failed";
			//TODO: set exit code, how?
		}
		
		Window.Close();
	}
	
	protected void Add( TestCase tc )
	{
		TestRunner.Add(tc);
	}

	bool _firstUpdate = true;
	protected override void OnUpdate()
	{
		base.OnUpdate();
		
		if (_firstUpdate)
		{
			_firstUpdate = false;
			TestRunner.Run();
		}
		else
		{
			TestRunner.CheckUpdate();
		}
	}
}
