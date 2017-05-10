package com.fusetools.webview;
import android.webkit.WebView;
import android.webkit.WebChromeClient;
import android.webkit.ValueCallback;
import android.net.Uri;
import com.foreign.Uno.Action_int;

public class FuseWebChromeClient extends WebChromeClient
{
	Action_int _handler;
	public FuseWebChromeClient(Action_int handler)
	{
		super();
		_handler = handler;
	}
	
	@Override
	public void onProgressChanged(WebView view, int progress)
	{
		super.onProgressChanged(view, progress);
		_handler.run(progress);
	}
	
	@Override
	public boolean onShowFileChooser (WebView webView, ValueCallback<Uri[]> filePathCallback, WebChromeClient.FileChooserParams fileChooserParams)
	{
		//TODO: Implement file chooser API via JS callbacks
		return super.onShowFileChooser(webView, filePathCallback, fileChooserParams);
	}
}
