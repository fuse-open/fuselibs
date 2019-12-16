package com.fuse.fileprovider;

import androidx.core.content.FileProvider;

/**
 * Providing a custom {@code FileProvider} prevents manifest {@code <provider>} name collisions.
 *
 * See https://developer.android.com/guide/topics/manifest/provider-element.html for details.
 */
public class CameraFileProvider extends FileProvider {

    // This class intentionally left blank.

}