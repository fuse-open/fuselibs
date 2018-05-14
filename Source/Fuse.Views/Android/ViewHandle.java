package com.fuse.views;

import com.uno.UnoObject;
import com.fuse.views.internal.FuseView;

public class ViewHandle {

	private UnoObject _handle;
	private FuseView _fuseView;

	public ViewHandle(UnoObject handle, FuseView fuseView) {
		_handle = handle;
		_fuseView = fuseView;
	}

	public android.view.View getView() {
		return _fuseView;
	}

	public void setDataJson(String json) {
		_fuseView.setDataJson(json);
	}

	public void setDataString(String key, String value) {
		_fuseView.setDataString(key, value);
	}

	public void setCallback(String key, com.fuse.views.ICallback callback) {
		_fuseView.setCallback(key, callback);
	}

}