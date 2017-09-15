package com.fuse.PushNotifications;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.HashMap;

public class BundleFiles
{
	private static HashMap<String, HashMap<String, String>> bundled = null;

	private static void PopulateBundleInfo(Context context)
	{
		if (bundled != null) return;

		bundled = new HashMap<>();
		BufferedReader reader = null;
		try
		{
			reader = new BufferedReader(new InputStreamReader(context.getAssets().open("bundle"), "UTF-8"));
			String mLine;
			while ((mLine = reader.readLine()) != null)
			{
				String[] split = mLine.split(":");
				if (split.length > 1)
				{
					String pkg = split[0];
					HashMap<String, String> bundle = new HashMap<>();
					for (int i = 1; i < split.length; i += 2)
					{
						String bdlName = split[i];
						String fileName = split[i + 1];
						bundle.put(bdlName, fileName);
					}
					bundled.put(pkg, bundle);
				}
			}
		}
		catch (IOException e)
		{
			Log.e("RecievePushNotifications", "Could not read bundle file index");
		}
		finally
		{
			if (reader != null)
			{
				try
				{
					reader.close();
				}
				catch (IOException e)
				{
					Log.e("RecievePushNotifications", "Could not close bundle file index");
				}
			}
		}
	}

	public static String GetPathToBundled(Context context, String packageName, String name)
	{
		PopulateBundleInfo(context);
		HashMap<String, String> pkg = bundled.get(packageName);
		if (pkg != null)
			return pkg.get(name);
		else
			return null;
	}

	public static InputStream OpenBundledFile(Context context, String packageName, String name)
	{
		String bdlPath = GetPathToBundled(context, packageName, name);
		if (bdlPath == null) return null;
		AssetManager am = context.getAssets();
		try
		{
			return am.open(bdlPath);
		}
		catch (IOException e)
		{
			return null;
		}
	}
}
