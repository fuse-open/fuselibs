package com.fuse.views;

import com.fuse.views.internal.IExportedViews;

public class ExportedViews {

	private static ExportedViews _instance = null;

	private IExportedViews _impl;

	private ExportedViews(IExportedViews impl) {
		_impl = impl;
	}

	private static ExportedViews getInstance() {
		return _instance;
	}

	public static void initialize(IExportedViews impl) {
		_instance = new ExportedViews(impl);
	}

	public static com.fuse.views.ViewHandle instantiate(String uxClassName) {
		return getInstance()._impl.instantiate(uxClassName);
	}

}