using Uno;
using Uno.Collections;
using Uno.Threading;

using Fuse;
using Fuse.Elements;
using Fuse.Triggers;

namespace FuseTest
{
	public class DiagnosticException : Exception
	{
		public Diagnostic Diagnostic;

		public DiagnosticException(Diagnostic d) : base(d.ToString(), d.Exception)
		{
			this.Diagnostic = d;
		}
	}

	public class RecordDiagnosticGuard : IDisposable
	{
		//records all diagnostics that happen since last DequeueAll
		ConcurrentQueue<Diagnostic> _diagnosticsQueue = new ConcurrentQueue<Diagnostic>();

		public IList<Diagnostic> DequeueAll()
		{
			var ret = new List<Diagnostic>();
			while (true)
			{
				Diagnostic d;
				if (!_diagnosticsQueue.TryDequeue(out d))
					break;

				ret.Add(d);
			}

			return ret;
		}

		public RecordDiagnosticGuard()
		{ 
			if (TestBase._allowDiagnostics)
				throw new Exception("Diagnostics already allowed");

			TestBase._allowDiagnostics = true;
			Diagnostics.DiagnosticReported += OnDiagnostic;
		}
		
		void OnDiagnostic(Diagnostic d)
		{
			if (!d.IsTemporalWarning)
				_diagnosticsQueue.Enqueue(d);
		}

		public void Dispose()
		{
			if (!TestBase._allowDiagnostics)
				throw new Exception("Diagnostics not allowed");

			TestBase._allowDiagnostics = false;
			Diagnostics.DiagnosticReported -= OnDiagnostic;

			if (_diagnosticsQueue.Count > 0)
				throw new Exception("Unchecked, queued Diagnostics!");
		}
	}

	public class TestBase
	{
		static readonly Thread MainThread;
		static TestBase()
		{
			MainThread = Thread.CurrentThread;
			Diagnostics.DiagnosticReported += DispatchDiagnostic;
		}

		static internal bool _allowDiagnostics;

		static void DispatchDiagnostic(Diagnostic d)
		{
			if (!_allowDiagnostics)
			{
				if (Thread.CurrentThread == MainThread)
					OnDiagnosticReported(d);
				else
					UpdateManager.PostAction(new DiagnosticDispatch{ Diagnostic = d, Handler = OnDiagnosticReported }.Post);
			}
		}

		static void OnDiagnosticReported(Diagnostic d)
		{
			if (!d.IsTemporalWarning)
				throw new DiagnosticException(d);
		}

		internal class DiagnosticDispatch
		{
			public Diagnostic Diagnostic;
			public DiagnosticHandler Handler;

			public void Post()
			{
				Handler(Diagnostic);
			}
		}

		static public T[] GetChildren<T>( Visual v ) where T : class
		{
			var list = new List<T>();
			for (int i=0; i < v.Children.Count; ++i)
			{
				var q = v.Children[i] as T;
				if (q != null)
					list.Add(q);
			}
			return list.ToArray();
		}
		
		static string ConcatList(string a, string b)
		{
			if (b == "")
				return a;
			if (a == "")
				return b;
			return a + "," + b;
		}
		
		static public string GetText(Visual p)
		{
			var q = "";
			for (int i=0; i < p.Children.Count; ++i)
			{
				var c = p.Children[i];
				var t = c as Fuse.Controls.Text;
				if (t != null)
					q = ConcatList(q,t.Value);
			}
			return q;
		}
		
		static public string GetRecursiveText(Visual p)
		{
			var q = "";
			for (int i=0; i < p.Children.Count; ++i)
			{
				var c = p.Children[i];
				var t = c as Fuse.Controls.Text;
				if (t != null)
					q = ConcatList(q,t.Value);
				
				var v = c as Visual;
				if (v != null)
					q = ConcatList(q, GetRecursiveText(v));
			}
			return q;
		}
		
		/** Get a stringified version of the UseValue's of the DudElement children in Z order */
		static public string GetDudZ(Visual root)
		{
			var q = "";
			
			var zOrder = root.GetCachedZOrder();

			for (int i = 0; i < zOrder.Length; ++i)
			{
				var t = zOrder[i] as FuseTest.DudElement;
				if (t != null)
				{
					if (q.Length > 0)
						q += ",";
					q += t.UseValue;
				}
			}
			return q;
		}
		
		
		/**
			Use this rather than access Progress directly. It limits how many projects we have
			to expose Internals to.
		*/
		protected double TriggerProgress( Trigger t )
		{
			return t.Progress;
		}
		
		protected float4 ActualPositionSize( Element e)
		{
			return float4( e.ActualPosition, e.ActualSize );
		}
		
		protected float GestureHardCaptureSignificanceThreshold
		{
			get { return Fuse.Input.Gesture.HardCaptureSignificanceThreshold; }
		}
	}
}
