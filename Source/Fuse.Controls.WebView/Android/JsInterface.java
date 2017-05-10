package com.fusetools.webview;
import com.foreign.Uno.Action_String;
import android.webkit.JavascriptInterface;

public class JsInterface
{
	Action_String _handler;
	public JsInterface(Action_String handler)
	{
		_handler = handler;
	}
	
	@JavascriptInterface
	public void onResult(String result) 
	{
		_handler.run(result);
	}
}
