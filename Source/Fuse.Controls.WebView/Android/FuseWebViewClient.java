package com.fusetools.webview;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.graphics.Bitmap;
import com.foreign.Uno.Action;
import com.foreign.Uno.Action_String;
import com.uno.StringArray;

public class FuseWebViewClient extends WebViewClient
{
	boolean redirect;
	boolean loadingFinished;
	
	Action _pageLoadedAction; 
	Action _pageStartedAction; 
	Action _urlChangedAction; 
	Action_String _onCustomURI;
	String[] _customURIs;
	
	public FuseWebViewClient(Action loaded, Action started, Action changed, Action_String onCustomURI, StringArray customURIs)
	{
		super();
		_pageLoadedAction = loaded;
		_pageStartedAction = started;
		_urlChangedAction = changed;
		_onCustomURI = onCustomURI;
		_customURIs = customURIs.copyArray();
		loadingFinished = true;
		redirect = false;
	}
	
	@Override
	public boolean shouldOverrideUrlLoading(WebView view, String url) 
	{
		for(String uri : _customURIs)
		{
			if(url.indexOf(uri) != -1)
			{
				_onCustomURI.run(url);
				return true;
			}
		}
		if(!loadingFinished){
			redirect = true;
		}else{
			if (_pageStartedAction != null)
				_pageStartedAction.run();
		}
		loadingFinished = false;
		view.loadUrl(url);
		return true;
	}
	
	@Override
	public void onPageStarted(WebView view, String url, Bitmap favIcon)
	{
		if(loadingFinished){
			if (_pageStartedAction != null)
				_pageStartedAction.run();
		}
		loadingFinished = false;
	}
	
	@Override
	public void onPageFinished(WebView view, String url)
	{
		if(_urlChangedAction != null)
				_urlChangedAction.run();

		if(!redirect)
			loadingFinished = true;
			
		if(loadingFinished && !redirect){
			loadingFinished = true;
			if (_pageLoadedAction != null)
				_pageLoadedAction.run();
		}else{
			redirect = false;
		}
	}
}
