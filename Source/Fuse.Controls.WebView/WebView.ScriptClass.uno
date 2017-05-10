using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Controls
{
	/** The native WebView for iOS & Android
		@scriptmodule FuseJS/Push

		@include Docs/Guide.md
	*/
	public partial class WebView
	{
		static WebView()
		{
			ScriptClass.Register(typeof(WebView),
				new ScriptMethod<WebView>("goto", setUrl, ExecutionThread.MainThread),
				new ScriptMethod<WebView>("loadHtml", loadHtml, ExecutionThread.MainThread),
				new ScriptMethod<WebView>("setBaseUrl", setBaseUrl, ExecutionThread.MainThread));
		}

		/**
			Loads an HTML document from the string provided.

			@scriptmethod loadHtml(html)
			@scriptmethod loadHtml(html, baseUrl)
			@param html The document to load into the WebView.
			@param baseUrl Specifies the base URL used to resolve relative locations in the @html parameter.
		*/
		static void loadHtml(Context c, WebView view, object[] args)
		{

			switch(args.Length)
			{
				case 1:
					view.LoadHtml(args[0] as string);
					return;
				case 2:
					view.LoadHtml(args[0] as string, args[1] as string);
					return;
				default:
					Fuse.Diagnostics.UserError("WebView.loadHtml takes either one url argument, or an url and a baseUrl argument", view);
					return;
			}

		}

		/**
			Load a URL in the WebView.

			@scriptmethod goto(url)
			@param url The location to load.
		*/
		static void setUrl(Context c, WebView view, object[] args)
		{
			switch(args.Length)
			{
				case 1:
					view.Url = args[0] as string;
					return;
				default:
					Fuse.Diagnostics.UserError( "WebView.setUrl requires 1 string argument", view);
					return;
			}
		}

		/**
			Sets the base url used to resolve relative requests on a page (loaded via @loadHtml)

			@scriptmethod setBaseUrl(baseUrl)
			@param baseUrl The base URL used to resolve relative locations.
		*/
		static void setBaseUrl(Context c, WebView view, object[] args)
		{
			switch(args.Length)
			{
				case 1:
					view.BaseUrl = args[0] as string;
					return;
				default:
					Fuse.Diagnostics.UserError( "WebView.setBaseUrl requires 1 string argument", view );
					return;
			}
		}

		//TODO: Implement with callback somehow
		static void evaluateJs(Context c, WebView view, object[] args)
		{
			switch(args.Length)
			{
				case 1:
					view.Eval(args[0] as string);
					return;
				default:
					Fuse.Diagnostics.UserError( "WebView.evaluateJs requires 1 string argument", view );
					return;

			}
		}
	}
}
