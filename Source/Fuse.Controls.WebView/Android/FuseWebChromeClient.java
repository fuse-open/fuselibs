package com.fuse.webview;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.JsResult;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.widget.FrameLayout;

import androidx.appcompat.app.AppCompatActivity;

import com.foreign.Uno.Action_int;

import com.vansuita.pickimage.bean.PickResult;
import com.vansuita.pickimage.bundle.PickSetup;
import com.vansuita.pickimage.dialog.PickImageDialog;
import com.vansuita.pickimage.listeners.IPickCancel;
import com.vansuita.pickimage.listeners.IPickResult;

public class FuseWebChromeClient extends WebChromeClient
{
	static final int REQUEST_CODE_FILE_PICKER = 51426;

	int _originalOrientation;
	ValueCallback<Uri[]> _filePathCallback;
	FullscreenHolder _fullscreenContainer;
	CustomViewCallback _customViewCallback;
	View _customView;
	AppCompatActivity _activity;
	Action_int _handler;

	public FuseWebChromeClient(Action_int handler)
	{
		super();
		_activity = com.fuse.Activity.getRootActivity();
		_handler = handler;
	}

	@Override
	public void onProgressChanged(WebView view, int progress)
	{
		super.onProgressChanged(view, progress);
		_handler.run(progress);
	}

	@Override
	public boolean onShowFileChooser(final WebView webView, ValueCallback<Uri[]> filePathCallback, WebChromeClient.FileChooserParams fileChooserParams) {
		// Cancel existing callback first, if any.
		onReceiveFileChooserValue(null);

		// Set callback for onReceiveFileChooserValue().
		_filePathCallback = filePathCallback;

		if (Build.VERSION.SDK_INT >= 21) {
			final boolean allowMultiple = fileChooserParams.getMode() == FileChooserParams.MODE_OPEN_MULTIPLE;

			if (!allowMultiple) {
				// Show a dialog where we can pick images using Camera or Gallery.

				PickImageDialog dialog = PickImageDialog
						.build(new PickSetup().setVideo(false))
						.setOnPickResult(new IPickResult() {
							@Override
							public void onPickResult(PickResult r) {
								onReceiveFileChooserValue(new Uri[]{ r.getUri() });
							}
						})
						.setOnPickCancel(new IPickCancel() {
							@Override
							public void onCancelClick() {
								onReceiveFileChooserValue(null);
							}
						});

				// It's possible to cancel the dialog without receiving onCancelClick(), for example
				// when tapping on the background or when using the back button.

				// However, if we don't call onReceiveFileChooserValue(), it is no longer possible
				// to open more dialogs. onShowFileChooser() just never gets called again...

				// So, to workaround the problem, we'll listen for any touch events from WebView,
				// make sure to call onReceiveFileChooserValue(), and this trick makes it possible
				// to open another dialog!

				webView.setOnTouchListener(new View.OnTouchListener() {
					@Override
					public boolean onTouch(View view, MotionEvent event) {
						onReceiveFileChooserValue(null);
						return false;
					}
				});

				dialog.show(_activity.getSupportFragmentManager());
				return true;
			}

			// Fallback:

			Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
			intent.addCategory(Intent.CATEGORY_OPENABLE);
			intent.setType("*/*");

			if (allowMultiple) {
				if (Build.VERSION.SDK_INT >= 18) {
					intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
				}
			}

			com.fuse.Activity.ResultListener listener = new com.fuse.Activity.ResultListener() {
				@Override
				public boolean onResult(int requestCode, int resultCode, Intent intent) {
					if (requestCode == REQUEST_CODE_FILE_PICKER) {
						if (resultCode == Activity.RESULT_OK) {
							if (intent != null) {
								Uri[] dataUris = null;

								try {
									if (intent.getDataString() != null) {
										dataUris = new Uri[] { Uri.parse(intent.getDataString()) };
									}
									else {
										if (Build.VERSION.SDK_INT >= 16) {
											if (intent.getClipData() != null) {
												final int numSelectedFiles = intent.getClipData().getItemCount();

												dataUris = new Uri[numSelectedFiles];

												for (int i = 0; i < numSelectedFiles; i++) {
													dataUris[i] = intent.getClipData().getItemAt(i).getUri();
												}
											}
										}
									}
								}
								catch (Exception e) {
									Log.e("FuseWebChromeClient", e.toString());
								}

								onReceiveFileChooserValue(dataUris);
							}
						}
						else {
							onReceiveFileChooserValue(null);
						}

						com.fuse.Activity.unsubscribeFromResults(this);
					}

					return true;
				}
			};

			com.fuse.Activity.subscribeToResults(listener);
			_activity.startActivityForResult(Intent.createChooser(intent, "Choose File"), REQUEST_CODE_FILE_PICKER);
			return true;
		} else {
			return super.onShowFileChooser(webView, filePathCallback, fileChooserParams);
		}
	}

	private void onReceiveFileChooserValue(Uri[] value) {
		if (_filePathCallback != null) {
			_filePathCallback.onReceiveValue(value);
			_filePathCallback = null;
		}
	}

	@Override
	public boolean onJsAlert(WebView view, String url, String message, JsResult result) {
		result.confirm();
		return super.onJsAlert(view, url, message, result);
	}

	@Override
	public void onShowCustomView(View view, CustomViewCallback callback) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
			if (_customView != null) {
				callback.onCustomViewHidden();
				return;
			}

			_originalOrientation = _activity.getRequestedOrientation();

			FrameLayout decor = (FrameLayout) _activity.getWindow().getDecorView();

			_fullscreenContainer = new FullscreenHolder(_activity);
			_fullscreenContainer.addView(view, ViewGroup.LayoutParams.MATCH_PARENT);
			decor.addView(_fullscreenContainer, ViewGroup.LayoutParams.MATCH_PARENT);
			_customView = view;
			setFullscreen(true);
			_customViewCallback = callback;
			_activity.setRequestedOrientation(_originalOrientation);
		}
		super.onShowCustomView(view, callback);
	}

	@Override
	public void onHideCustomView() {
		if (_customView == null) {
			return;
		}

		setFullscreen(false);

		FrameLayout decor = (FrameLayout) _activity.getWindow().getDecorView();
		decor.removeView(_fullscreenContainer);
		_fullscreenContainer = null;
		_customView = null;
		_customViewCallback.onCustomViewHidden();

		_activity.setRequestedOrientation(_originalOrientation);
	}

	private void setFullscreen(boolean enabled) {

		Window win = _activity.getWindow();
		WindowManager.LayoutParams winParams = win.getAttributes();
		final int bits = WindowManager.LayoutParams.FLAG_FULLSCREEN;
		if (enabled) {
			winParams.flags |= bits;
		} else {
			winParams.flags &= ~bits;
			if (_customView != null) {
				_customView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_VISIBLE);
			}
		}
		win.setAttributes(winParams);
	}

	static class FullscreenHolder extends FrameLayout {

		public FullscreenHolder(Context ctx) {
			super(ctx);
			setBackgroundColor(ctx.getResources().getColor(android.R.color.black));
		}

		@Override
		public boolean onTouchEvent(MotionEvent evt) {
			return true;
		}
	}
}
