package com.fuse.mediapicker;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.hardware.camera2.CameraCharacteristics;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import androidx.annotation.VisibleForTesting;
import androidx.core.app.ActivityCompat;
import androidx.core.content.FileProvider;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import com.foreign.Uno.Action_String;
import android.widget.Toast;

enum CameraDevice {
	REAR,

	FRONT
}

public class MediaPickerImpl {

	static final int REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY = 2342;
	static final int REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA = 2343;
	static final int REQUEST_CAMERA_IMAGE_PERMISSION = 2345;
	static final int REQUEST_CODE_CHOOSE_MULTI_IMAGE_FROM_GALLERY = 2346;
	static final int REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY = 2352;
	static final int REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA = 2353;
	static final int REQUEST_CAMERA_VIDEO_PERMISSION = 235;
	private final ImageResizer imageResizer;
	private final PermissionManager permissionManager;
	private final FileUriResolver fileUriResolver;
	private final FileUtils fileUtils;
	private CameraDevice cameraDevice;
	final String fileProviderName;
	final File externalFilesDirectory;

	interface PermissionManager {
		boolean isPermissionGranted(String permissionName);

		void askForPermission(String permissionName, int requestCode);

		boolean needRequestCameraPermission();
	}

	interface FileUriResolver {
		Uri resolveFileProviderUriForFile(String fileProviderName, File imageFile);

		void getFullImagePath(Uri imageUri, OnPathReadyListener listener);
	}

	interface OnPathReadyListener {
		void onPathReady(String path);
	}

	private Uri pendingCameraMediaUri;
	private Action_String result;
	private Action_String reject;
	private Map<String, Object> arguments;
	private static MediaPickerImpl instance;

	public static MediaPickerImpl getInstance() {
		if (instance != null)
			return instance;

		final File externalFilesDirectory = com.fuse.Activity.getRootActivity().getCacheDir();
		final ExifDataCopier exifDataCopier = new ExifDataCopier();
		final ImageResizer imageResizer = new ImageResizer(externalFilesDirectory, exifDataCopier);
		instance = new MediaPickerImpl(externalFilesDirectory, imageResizer);
		return instance;
	}

	private MediaPickerImpl(
			final File externalFilesDirectory,
			final ImageResizer imageResizer) {
		this(
				externalFilesDirectory,
				imageResizer,
				new PermissionManager() {
					@Override
					public boolean isPermissionGranted(String permissionName) {
						return ActivityCompat.checkSelfPermission(com.fuse.Activity.getRootActivity(), permissionName)
								== PackageManager.PERMISSION_GRANTED;
					}

					@Override
					public void askForPermission(String permissionName, int requestCode) {
						ActivityCompat.requestPermissions(com.fuse.Activity.getRootActivity(), new String[] {permissionName}, requestCode);
					}

					@Override
					public boolean needRequestCameraPermission() {
						return MediaPickerUtils.needRequestCameraPermission(com.fuse.Activity.getRootActivity());
					}
				},
				new FileUriResolver() {
					@Override
					public Uri resolveFileProviderUriForFile(String fileProviderName, File file) {
						return FileProvider.getUriForFile(com.fuse.Activity.getRootActivity(), fileProviderName, file);
					}

					@Override
					public void getFullImagePath(final Uri imageUri, final OnPathReadyListener listener) {
						MediaScannerConnection.scanFile(
							com.fuse.Activity.getRootActivity(),
								new String[] {(imageUri != null) ? imageUri.getPath() : ""},
								null,
								new MediaScannerConnection.OnScanCompletedListener() {
									@Override
									public void onScanCompleted(String path, Uri uri) {
										listener.onPathReady(path);
									}
								});
					}
				},
				new FileUtils());
	}

	private MediaPickerImpl(final File externalFilesDirectory, final ImageResizer imageResizer, final PermissionManager permissionManager, final FileUriResolver fileUriResolver, final FileUtils fileUtils) {
		this.externalFilesDirectory = externalFilesDirectory;
		this.imageResizer = imageResizer;
		this.fileProviderName = com.fuse.Activity.getRootActivity().getPackageName() + ".media_picker_file_provider";
		this.permissionManager = permissionManager;
		this.fileUriResolver = fileUriResolver;
		this.fileUtils = fileUtils;
		com.fuse.Activity.ResultListener l = new com.fuse.Activity.ResultListener() {
			@Override
			public boolean onResult(int requestCode, int resultCode, android.content.Intent data) {
				return MediaPickerImpl.this.onActivityResult(requestCode, resultCode, data);
			}
		};
		com.fuse.Activity.subscribeToResults(l);
	}

	void setCameraDevice(CameraDevice device) {
		cameraDevice = device;
	}

	void setArguments(Map<String, Object> arguments) {
		this.arguments = arguments;
	}

	void setResult(Action_String result) {
		this.result = result;
	}

	void setReject(Action_String reject) {
		this.reject = reject;
	}

	CameraDevice getCameraDevice() {
		return cameraDevice;
	}

	public void launchPickVideoFromGalleryIntent() {
		Intent pickVideoIntent = new Intent(Intent.ACTION_GET_CONTENT);
		pickVideoIntent.setType("video/*");

		com.fuse.Activity.getRootActivity().startActivityForResult(pickVideoIntent, REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY);
	}

	public void takeVideoWithCamera() {
		if (needRequestCameraPermission()
				&& !permissionManager.isPermissionGranted(Manifest.permission.CAMERA)) {
			permissionManager.askForPermission(
					Manifest.permission.CAMERA, REQUEST_CAMERA_VIDEO_PERMISSION);
			return;
		}

		launchTakeVideoWithCameraIntent();
	}

	private void launchTakeVideoWithCameraIntent() {
		Intent intent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);
		if (this.arguments.get("maxDuration") != null) {
			int maxSeconds = (int)this.arguments.get("maxDuration");
			if (maxSeconds > 0)
				intent.putExtra(MediaStore.EXTRA_DURATION_LIMIT, maxSeconds);
		}
		if (cameraDevice == CameraDevice.FRONT) {
			useFrontCamera(intent);
		}

		File videoFile = createTemporaryWritableVideoFile();
		pendingCameraMediaUri = Uri.parse("file:" + videoFile.getAbsolutePath());

		Uri videoUri = fileUriResolver.resolveFileProviderUriForFile(fileProviderName, videoFile);
		intent.putExtra(MediaStore.EXTRA_OUTPUT, videoUri);
		grantUriPermissions(intent, videoUri);

		try {
			com.fuse.Activity.getRootActivity().startActivityForResult(intent, REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA);
		} catch (ActivityNotFoundException e) {
			try {
				videoFile.delete();
			} catch (SecurityException exception) {
				exception.printStackTrace();
			}
			finishWithError("No cameras available for taking pictures.");
		}
	}

	public void launchPickImageFromGalleryIntent() {
		Intent pickImageIntent = new Intent(Intent.ACTION_GET_CONTENT);
		pickImageIntent.setType("image/*");

		com.fuse.Activity.getRootActivity().startActivityForResult(pickImageIntent, REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY);
	}

	public void launchMultiPickImageFromGalleryIntent() {
		Intent pickImageIntent = new Intent(Intent.ACTION_GET_CONTENT);
		pickImageIntent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
		pickImageIntent.setType("image/*");

		com.fuse.Activity.getRootActivity().startActivityForResult(pickImageIntent, REQUEST_CODE_CHOOSE_MULTI_IMAGE_FROM_GALLERY);
	}

	public void takeImageWithCamera() {
		if (needRequestCameraPermission()
				&& !permissionManager.isPermissionGranted(Manifest.permission.CAMERA)) {
			permissionManager.askForPermission(
					Manifest.permission.CAMERA, REQUEST_CAMERA_IMAGE_PERMISSION);
			return;
		}
		launchTakeImageWithCameraIntent();
	}

	private boolean needRequestCameraPermission() {
		if (permissionManager == null) {
			return false;
		}
		return permissionManager.needRequestCameraPermission();
	}

	private void launchTakeImageWithCameraIntent() {
		Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
		if (cameraDevice == CameraDevice.FRONT) {
			useFrontCamera(intent);
		}

		File imageFile = createTemporaryWritableImageFile();
		pendingCameraMediaUri = Uri.parse("file:" + imageFile.getAbsolutePath());

		Uri imageUri = fileUriResolver.resolveFileProviderUriForFile(fileProviderName, imageFile);
		intent.putExtra(MediaStore.EXTRA_OUTPUT, imageUri);
		grantUriPermissions(intent, imageUri);

		try {
			com.fuse.Activity.getRootActivity().startActivityForResult(intent, REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA);
		} catch (ActivityNotFoundException e) {
			try {
				imageFile.delete();
			} catch (SecurityException exception) {
				exception.printStackTrace();
			}
			finishWithError("No cameras available for taking pictures.");
		}
	}

	private File createTemporaryWritableImageFile() {
		return createTemporaryWritableFile(".jpg");
	}

	private File createTemporaryWritableVideoFile() {
		return createTemporaryWritableFile(".mp4");
	}

	private File createTemporaryWritableFile(String suffix) {
		String filename = UUID.randomUUID().toString();
		File image;

		try {
			externalFilesDirectory.mkdirs();
			image = File.createTempFile(filename, suffix, externalFilesDirectory);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}

		return image;
	}

	private void grantUriPermissions(Intent intent, Uri imageUri) {
		PackageManager packageManager = com.fuse.Activity.getRootActivity().getPackageManager();
		List<ResolveInfo> compatibleActivities = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);

		for (ResolveInfo info : compatibleActivities) {
			com.fuse.Activity.getRootActivity().grantUriPermission(
					info.activityInfo.packageName,
					imageUri,
					Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
		}
	}

	public static boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
		boolean permissionGranted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;

		switch (requestCode) {
			case REQUEST_CAMERA_IMAGE_PERMISSION:
				if (permissionGranted) {
					MediaPickerImpl.getInstance().launchTakeImageWithCameraIntent();
				}
				break;
			case REQUEST_CAMERA_VIDEO_PERMISSION:
				if (permissionGranted) {
					MediaPickerImpl.getInstance().launchTakeVideoWithCameraIntent();
				}
				break;
			default:
				return false;
		}

		if (!permissionGranted) {
			switch (requestCode) {
				case REQUEST_CAMERA_IMAGE_PERMISSION:
				case REQUEST_CAMERA_VIDEO_PERMISSION:
					MediaPickerImpl.getInstance().finishWithError("The user did not allow camera access.");
					break;
			}
		}
		return true;
	}

	public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
		switch (requestCode) {
			case REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY:
				handleChooseImageResult(resultCode, data);
				break;
			case REQUEST_CODE_CHOOSE_MULTI_IMAGE_FROM_GALLERY:
				handleChooseMultiImageResult(resultCode, data);
				break;
			case REQUEST_CODE_TAKE_IMAGE_WITH_CAMERA:
				handleCaptureImageResult(resultCode);
				break;
			case REQUEST_CODE_CHOOSE_VIDEO_FROM_GALLERY:
				handleChooseVideoResult(resultCode, data);
				break;
			case REQUEST_CODE_TAKE_VIDEO_WITH_CAMERA:
				handleCaptureVideoResult(resultCode);
				break;
			default:
				return false;
		}

		return true;
	}

	private void handleChooseImageResult(int resultCode, Intent data) {
		if (resultCode == Activity.RESULT_OK && data != null) {
			String path = fileUtils.getPathFromUri(com.fuse.Activity.getRootActivity(), data.getData());
			handleImageResult(path, false);
			return;
		}

		// User cancelled choosing a picture.
		finishWithError("User cancelled choosing a picture");
	}

	private void handleChooseMultiImageResult(int resultCode, Intent intent) {
		if (resultCode == Activity.RESULT_OK && intent != null) {
			ArrayList<String> paths = new ArrayList<>();
			if (intent.getClipData() != null) {
				int maxImages = (int)this.arguments.get("maxImages");
				if (maxImages > 0 && intent.getClipData().getItemCount() > maxImages) {
					String message = "Error: Maximum selected images is " + maxImages;
					Toast.makeText(com.fuse.Activity.getRootActivity(), message, Toast.LENGTH_SHORT).show();
					finishWithError(message);
					return;
				}
				for (int i = 0; i < intent.getClipData().getItemCount(); i++) {
					paths.add(fileUtils.getPathFromUri(com.fuse.Activity.getRootActivity(), intent.getClipData().getItemAt(i).getUri()));
				}
			} else {
				paths.add(fileUtils.getPathFromUri(com.fuse.Activity.getRootActivity(), intent.getData()));
			}
			handleMultiImageResult(paths, false);
			return;
		}

		// User cancelled choosing a picture.
		finishWithError("User cancelled choosing a picture");
	}

	private void handleChooseVideoResult(int resultCode, Intent data) {
		if (resultCode == Activity.RESULT_OK && data != null) {
			String path = fileUtils.getPathFromUri(com.fuse.Activity.getRootActivity(), data.getData());
			handleVideoResult(path);
			return;
		}

		// User cancelled choosing a picture.
		finishWithError("User cancelled choosing a picture");
	}

	private void handleCaptureImageResult(int resultCode) {
		if (resultCode == Activity.RESULT_OK) {
			fileUriResolver.getFullImagePath(pendingCameraMediaUri,
					new OnPathReadyListener() {
						@Override
						public void onPathReady(String path) {
							handleImageResult(path, true);
						}
					});
			return;
		}
		finishWithError("User cancelled choosing a picture");
	}

	private void handleCaptureVideoResult(int resultCode) {
		if (resultCode == Activity.RESULT_OK) {
			fileUriResolver.getFullImagePath(pendingCameraMediaUri,
					new OnPathReadyListener() {
						@Override
						public void onPathReady(String path) {
							handleVideoResult(path);
						}
					});
			return;
		}
		finishWithError("User cancelled choosing a picture");
	}

	private void handleMultiImageResult(ArrayList<String> paths, boolean shouldDeleteOriginalIfScaled) {
		if (this.arguments != null) {
			ArrayList<String> finalPath = new ArrayList<>();
			for (int i = 0; i < paths.size(); i++) {
				String finalImagePath = getResizedImagePath(paths.get(i));
				if (finalImagePath != null && !finalImagePath.equals(paths.get(i)) && shouldDeleteOriginalIfScaled) {
					new File(paths.get(i)).delete();
				}
				finalPath.add(i, finalImagePath);
			}
			finishWithListSuccess(finalPath);
		} else {
			finishWithListSuccess(paths);
		}
	}

	private void handleImageResult(String path, boolean shouldDeleteOriginalIfScaled) {
		if (this.arguments != null) {
			String finalImagePath = getResizedImagePath(path);
			//delete original file if scaled
			if (finalImagePath != null && !finalImagePath.equals(path) && shouldDeleteOriginalIfScaled) {
				new File(path).delete();
			}
			finishWithSuccess(finalImagePath);
		} else {
			finishWithSuccess(path);
		}
	}

	private String getResizedImagePath(String path) {
		Double maxWidth = (double)this.arguments.get("maxWidth");
		Double maxHeight = (double)this.arguments.get("maxHeight");
		Integer imageQuality = (int)this.arguments.get("imageQuality");

		return imageResizer.resizeImageIfNeeded(path, maxWidth, maxHeight, imageQuality);
	}

	private void handleVideoResult(String path) {
		finishWithSuccess(path);
	}

	private void finishWithSuccess(String imagePath) {
		if (result == null) {
			return;
		}
		result.run(imagePath);
	}

	private void finishWithListSuccess(ArrayList<String> imagePaths) {
		if (result == null) {
			return;
		}
		String commaseparatedlist = imagePaths.toString();
		commaseparatedlist = commaseparatedlist.replace("[", "").replace("]", "").replace(" ", "");
		result.run(commaseparatedlist);
	}

	private void finishWithError(String errorMessage) {
		if (result == null) {
			return;
		}
		reject.run(errorMessage);
	}

	private void useFrontCamera(Intent intent) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
			intent.putExtra("android.intent.extras.CAMERA_FACING", CameraCharacteristics.LENS_FACING_FRONT);
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
				intent.putExtra("android.intent.extra.USE_FRONT_CAMERA", true);
			}
		} else {
			intent.putExtra("android.intent.extras.CAMERA_FACING", 1);
		}
	}
}
