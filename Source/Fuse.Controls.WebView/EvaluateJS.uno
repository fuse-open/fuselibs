using Uno;
using Uno.UX;
using Fuse.Controls;
using Fuse.Scripting;

namespace Fuse.Triggers.Actions
{

	public sealed class JSEventArgs : EventArgs, Fuse.Scripting.IScriptEvent
	{
		public readonly string ResultJson;
		public JSEventArgs(string resultJson) : base()
		{
			ResultJson = resultJson;
		}

		void Fuse.Scripting.IScriptEvent.Serialize(IEventSerializer s)
		{
			s.AddString("json", ResultJson);
		}
	}

	public delegate void JSEventHandler(object sender, JSEventArgs args);

	/** Evaluate a JavaScript snippet on a WebView and optionally get the result

		The WebView offers limited execution of arbitrary JavaScript in the currently loaded web environment. This is done with the `<EvaluateJS/>` action. Let's look at a simplified example.

		```XML
		<EvaluateJS Handler="{onPageLoaded}">
			var result = {
				url : document.location.href
			};
			return result;
		</EvaluateJS>
		```

		Note the use of a `return` statement in the script body. Implementations of JavaScript evaluation APIs generally act like a JavaScript [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop), and when evaluating multiple lines of JS the result of the last statement of the script becomes the returned value. For instance, "1+5" is completely valid JS when evaluated and returns the expected value of "6".

		This can result in odd-feeling JS, where referencing an object becomes an implicit return statement, whereas an explicit return is not allowed.

		```JavaScript
		var result = {};
		result.foo = "bar";
		result; // using return here is invalid JS
		```

		To make this feel better and allow return, we currently inject the user's JS in the form of a function:

		```JavaScript
		(function() { USER_JS })();
		```

		#### Reading the result value

		When we evaluate the JavaScript we are currently bound by platform restrictions in a key way: String is the only allowed return value type on Android, our lowest common denominator.
		What this means is that any return value passed from the evaluated script must by necessity be returned as JSON and parsed back from it on the Fuse end. Even if all you want is the result of some arithmetic, you'd still receive it as a string and require a cast. Instead of forcing you to routinely `return JSON.stringify(foo)` from your own JS we handle this by *always* wrapping your JS in JSON.stringify before evaluation:

		```JavaScript
		JSON.stringify( (function() { USER_JS })() );
		```

		The returned JSON string here is then put into a result object with the `json` key. This is for clarity, so you never forget that the data you are receiving is a JSON string that you will need to parse.

		```XML
		<JavaScript>
			module.exports = {
				onPageLoaded : function(result)
				{
					var url = JSON.parse(result.json).url;
				}
			};
		</JavaScript>
		```

		Note that of course return is optional. If you don't return anything from your evaluated JS the return value of the expression will simply be "null".

		## Example

			<Grid Rows="0.15*, 1*">
				<JavaScript>
					var Observable = require('FuseJS/Observable');
					var webViewTitle = Observable("<Unknown>");

					function updateTitle(args) {
						webViewTitle.value = JSON.parse(args.json);
					};

					module.exports = {
						webViewTitle: webViewTitle.map(function(title) { return "HTML Title: " + title; }),
						updateTitle: updateTitle
					}
				</JavaScript>			
				<Text Value="{webViewTitle}" Alignment="Center" />
				<NativeViewHost>
					<WebView Url="https://www.fusetools.com">
						<PageLoaded>
							<EvaluateJS JavaScript="return window.document.title;" Handler="{updateTitle}" />
						</PageLoaded>
					</WebView>
				</NativeViewHost>
			</Grid>
	*/
	public class EvaluateJS : TriggerAction
	{
		string _rawSource;
		string _processedSource;

		public event JSEventHandler Handler;

		IWebView _target;
		public IWebView WebView {
			get { return _target; }
			set { _target = value; }
		}

		[UXContent,UXVerbatim]
		public string JavaScript
		{
			get { return _rawSource; }
			set 
			{ 
				_rawSource = value;
				_processedSource = PrepareScriptForEval(_rawSource); 
			}
		}


		string PrepareScriptForEval(string js)
		{
			if (js == null)
				return "";

			js = js.Trim();
			js = "JSON.stringify((function(){" + js + "})());";
			return js;
		}

		protected override void Perform(Node target)
		{
			var webView = _target ?? target.FindByType<IWebView>();

			if (webView != null && !string.IsNullOrEmpty(_rawSource))
			{
				Execute(webView);
			}
		}

		void Execute(IWebView webView)
		{
			webView.Eval(_processedSource, ResultHandler);
		}

		void ResultHandler(string result)
		{
			if (Handler != null)
				Handler(this, new JSEventArgs(result) );
		}
	}
}
