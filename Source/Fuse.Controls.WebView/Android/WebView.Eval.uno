using Uno;
using Uno.UX;
using Uno.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Navigation;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Android.Controls.WebViewUtils.WebViewForeign;

namespace Fuse.Android.Controls.WebViewUtils
{
	extern (Android) sealed internal class EvaluateJsCommand
	{		
		readonly Action<string> _handler;
		public readonly string JavaScript;
		
		public EvaluateJsCommand(string javaScript, Action<string> handler)
		{
			JavaScript = javaScript;
			_handler = handler;
		}
		
		public void Execute(Java.Object webViewHandle, string expression)
		{
			webViewHandle.LoadUrl("javascript:"+expression);
		}
		
		public void HandleResult(string result){
			if(_handler!=null)
				_handler(result);
		}
	}

	extern (Android) sealed public class JSEvalRequestManager
	{
		List<EvaluateJsCommand> _evaluateRequests = new List<EvaluateJsCommand>();
		EvaluateJsCommand _currentRequest;
		Java.Object _webViewHandle;
		string _interfaceName;
		public JSEvalRequestManager(Java.Object webViewHandle)
		{
			_webViewHandle = webViewHandle;
			_webViewHandle.AddJavascriptInterface(_interfaceName = "FuseJSInterface", OnJsResult);
		}
		
		public void EvaluateJs(string js, Action<string> handler)
		{
			var cmd = new EvaluateJsCommand(js, handler);
			_evaluateRequests.Add(cmd);
			if(_evaluateRequests.Count==1)
				NextRequest();
		}
		
		void NextRequest()
		{
			if(_evaluateRequests.Count==0) return;
			_currentRequest = _evaluateRequests[0];
			_evaluateRequests.RemoveAt(0);
			_currentRequest.Execute(_webViewHandle, CreateExpression(_currentRequest.JavaScript));
		}
		
		string CreateExpression(string original){
			return _interfaceName+".onResult( eval(\'"+original+"\') );";
		}
		
		void OnJsResult(string result)
		{
			_currentRequest.HandleResult(result);
			_currentRequest = null;
			NextRequest();
		}
	}
}
