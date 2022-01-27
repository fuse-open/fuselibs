package com.fuse.webview;

import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Environment;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.URLUtil;
import android.widget.Toast;
import androidx.core.app.ActivityCompat;
import com.foreign.Uno.Action_String_String;
import com.foreign.Uno.Action_String;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;

public class FuseDownloadListener implements DownloadListener
{
	Action_String _beginDownload;
	Action_String_String _fileDownloaded;

	public FuseDownloadListener(Action_String beginDownload, Action_String_String fileDownloaded)
	{
		_beginDownload = beginDownload;
		_fileDownloaded = fileDownloaded;
		checkDownloadPermission();
	}

	@Override
	public void onDownloadStart(final String url, String userAgent, String contentDisposition, String mimeType, long contentLength) {
		DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
		try {
			contentDisposition = URLDecoder.decode(contentDisposition, "UTF-8");
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		}
		contentDisposition = contentDisposition.substring(0, contentDisposition.lastIndexOf(";"));
		request.setMimeType(mimeType);

		final String filename = URLUtil.guessFileName(url, contentDisposition, mimeType);

		String cookies = CookieManager.getInstance().getCookie(url);
		request.addRequestHeader("cookie", cookies);
		request.addRequestHeader("User-Agent", userAgent);
		request.setDescription("Downloading file...");
		request.setTitle(filename);
		request.allowScanningByMediaScanner();
		request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
		request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, filename);
		DownloadManager dm = (DownloadManager) com.fuse.Activity.getRootActivity().getSystemService(Context.DOWNLOAD_SERVICE);
		dm.enqueue(request);
		com.fuse.Activity.getRootActivity().getApplicationContext().registerReceiver(new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				if (_fileDownloaded != null)
					_fileDownloaded.run(url, filename);
			}
		}, new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE));

		if (_beginDownload != null)
			_beginDownload.run(url);
	}

	private void checkDownloadPermission() {
		if (ActivityCompat.shouldShowRequestPermissionRationale(com.fuse.Activity.getRootActivity(), android.Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
			Toast.makeText(com.fuse.Activity.getRootActivity(), "Write External Storage permission allows us to save files. Please allow this permission in App Settings.", Toast.LENGTH_LONG).show();
		} else {
			ActivityCompat.requestPermissions(com.fuse.Activity.getRootActivity(), new String[]{android.Manifest.permission.WRITE_EXTERNAL_STORAGE}, 100);
		}
	}
}
