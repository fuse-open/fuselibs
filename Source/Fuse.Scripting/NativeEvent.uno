using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Scripting
{
	public sealed class NativeEvent : NativeProperty<Scripting.Function, Scripting.Function>
	{
		Queue<object[]> _eventArgsQueue;
		bool _queueEventsBeforeEvaluation;
		Scripting.Function _jsFunction;

		public NativeEvent(string name, bool queueEventsBeforeHandlerIsSet = true) : base(name)
		{
			_eventArgsQueue = new Queue<object[]>();
			_queueEventsBeforeEvaluation = queueEventsBeforeHandlerIsSet;
		}

		protected override void SetProperty(Scripting.Function function)
		{
			_jsFunction = function;
			DispatchQueue(ThreadWorker);
		}

		protected override Scripting.Function GetProperty()
		{
			return _jsFunction;
		}

		class CallDiscardingResultClosure
		{
			readonly Scripting.Function _jsFunction;
			readonly object[] _args;

			public CallDiscardingResultClosure(Scripting.Function jsFunction, object[] args)
			{
				_jsFunction = jsFunction;
				_args = args;
			}

			public void Run(Context context)
			{
				_jsFunction.CallDiscardingResult(context, _args);
			}
		}

		void DispatchQueue(IThreadWorker threadWorker)
		{
			while (_eventArgsQueue.Count > 0 && _jsFunction != null)
				threadWorker.Invoke(new CallDiscardingResultClosure(_jsFunction, _eventArgsQueue.Dequeue()).Run);
		}

		[Obsolete("Use `RaiseAsync(IThreadWorker, params object[])` instead")]
		public void RaiseAsync(params object[] args)
		{
			if(Context != null || _queueEventsBeforeEvaluation)
				_eventArgsQueue.Enqueue(args);

			DispatchQueue(Context != null ? Context.ThreadWorker : null);
		}

		public void RaiseAsync(IThreadWorker threadWorker, params object[] args)
		{
			if (ThreadWorker != null || _queueEventsBeforeEvaluation)
				_eventArgsQueue.Enqueue(args);

			DispatchQueue(threadWorker);
		}

		internal object RaiseSync(Context context, params object[] args)
		{
			if (_jsFunction != null)
				context.ThreadWorker.Invoke(new CallDiscardingResultClosure(_jsFunction, args).Run);

			return null;
		}
	}
}
