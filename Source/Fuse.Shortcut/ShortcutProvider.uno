using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;
using Uno.Collections;

namespace Fuse.Shortcut
{
	[ForeignInclude(Language.Java, "android.annotation.TargetApi", "android.os.Build", "android.content.pm.ShortcutInfo","android.content.pm.ShortcutManager", "android.content.Intent", "android.content.Context", "android.app.Activity", "android.content.res.AssetManager", "android.graphics.drawable.Icon")]
	[ForeignInclude(Language.ObjC, "iOS/FOShortcutHandler.h")]
	[Require("appDelegate.sourceFile.declaration", "#include <iOS/FOShortcutHandler.h>")]
	[Require("appDelegate.sourceFile.didFinishLaunchingWithOptions", "return [[FOShortcutHandler sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];")]
	[Require("appDelegate.sourceFile.implementationScope", "- (void)applicationDidBecomeActive:(UIApplication *)application { uAutoReleasePool pool; [[FOShortcutHandler sharedInstance] applicationDidBecomeActive:application]; }")]
	[Require("appDelegate.sourceFile.implementationScope", "- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler { uAutoReleasePool pool; [[FOShortcutHandler sharedInstance] application:application performActionForShortcutItem:shortcutItem completionHandler:completionHandler]; }")]
	public class ShortcutProvider
	{

		public static void RegisterShortcuts(string shortcuts, Action<string> callback)
		{
			if defined(iOS)
				RegisterIOSShortcuts(deserialize(shortcuts), callback);
			if defined(Android)
				RegisterAndroidShortcuts(deserialize(shortcuts), callback);
		}

		[Foreign(Language.ObjC)]
		extern(iOS) static ObjC.Object deserialize(string shortcuts)
		@{
			NSMutableArray * arrShortcuts = [[NSMutableArray alloc] init];
			arrShortcuts = [NSJSONSerialization JSONObjectWithData: [shortcuts dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
			for (NSMutableDictionary* item in arrShortcuts)
			{
				if (item[@"icon"] != nil)
				{
					NSString * path = @{GetBundlePath(string):call(item[@"icon"])};
					item[@"icon"] = [@"data/" stringByAppendingString:path];
				}
			}
			return arrShortcuts;
		@}

		[Foreign(Language.Java)]
		extern(Android) static Java.Object deserialize(string shortcuts)
		@{
			java.util.List<java.util.Map> listShortcuts = new java.util.ArrayList<>();
			try
			{
				org.json.JSONArray jsonArray = new org.json.JSONArray(shortcuts.trim());
				for (int i = 0; i < jsonArray.length(); i++)
				{
					Object jsonArrayValue = jsonArray.get(i);
					if (jsonArrayValue instanceof org.json.JSONObject) {
						java.util.Map<String, String> map = new java.util.HashMap<>();
						org.json.JSONObject jsonObject = (org.json.JSONObject)jsonArrayValue;
						java.util.Iterator<String> keys = jsonObject.keys();
						while(keys.hasNext())
						{
							String keyStr = keys.next();
							String keyValue = (String)jsonObject.get(keyStr);
							map.put(keyStr, keyValue);
						}
						listShortcuts.add(map);
					}
				}
			}
			catch (org.json.JSONException je) {
				je.printStackTrace();
			}
			return listShortcuts;
		@}

		[Foreign(Language.ObjC)]
		extern(iOS) static void RegisterIOSShortcuts(ObjC.Object data, Action<string> callback)
		@{
			[[FOShortcutHandler sharedInstance] registerShortcuts:(NSArray*)data];
			[[FOShortcutHandler sharedInstance] registerCallback:callback];
		@}

		[Foreign(Language.Java)]
		extern(Android) static void RegisterAndroidShortcuts(Java.Object data, Action<string> callback)
		@{
			// Do nothing for anything lower than API 25 as the functionality isn't supported.
			if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) {
				return;
			}

			com.fuse.Activity.IntentListener l = new com.fuse.Activity.IntentListener() {
				@Override public void onIntent(android.content.Intent data) {
					if (data.hasExtra("com.fuse.shortcut"))
					{
						String type = data.getStringExtra("com.fuse.shortcut");
						if (callback != null)
							callback.run(type);
					}
				}
			};
			com.fuse.Activity.subscribeToIntents(l, Intent.ACTION_RUN);

			final Activity context = com.fuse.Activity.getRootActivity();
			final String packageName = context.getPackageName();
			final AssetManager assets = context.getAssets();
			final java.util.List<ShortcutInfo> shortcutInfos = new java.util.ArrayList<>();

			java.util.List<java.util.Map<String, String>> shortcuts = (java.util.List<java.util.Map<String, String>>)data;
			for (java.util.Map<String, String> shortcut : shortcuts) {
				final String icon = shortcut.get("icon");
				final String type = shortcut.get("id");
				final String title = shortcut.get("title");
				final String subtitle = shortcut.get("subtitle");

				final ShortcutInfo.Builder shortcutBuilder = new ShortcutInfo.Builder(context, type);
				if (icon != null)
				{
					String path = @{GetBundlePath(string):call(icon)};
					if (path != "")
					{
						android.graphics.Bitmap bitmap = null;
						try
						{
							java.io.InputStream stream = assets.open(path);
							bitmap = android.graphics.BitmapFactory.decodeStream(stream);
							stream.close();
							shortcutBuilder.setIcon(Icon.createWithBitmap(bitmap));
						}
						catch (Exception e)
						{
							e.printStackTrace();
						}
					}
				}
				Intent intent = context.getPackageManager().getLaunchIntentForPackage(packageName).setAction(Intent.ACTION_RUN).putExtra("com.fuse.shortcut", type).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK);
				final ShortcutInfo shortcutInfo = shortcutBuilder.setLongLabel(subtitle == null ? title : subtitle).setShortLabel(title).setIntent(intent).build();
				shortcutInfos.add(shortcutInfo);
			}

			context.runOnUiThread(new Runnable() {
				@Override
				@TargetApi(Build.VERSION_CODES.N_MR1)
				public void run() {
					ShortcutManager shortcutManager = (ShortcutManager) context.getSystemService(Context.SHORTCUT_SERVICE);
					try {
						shortcutManager.removeAllDynamicShortcuts();
						shortcutManager.setDynamicShortcuts(shortcutInfos);
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
			});
		@}

		public static string GetBundlePath(string path)
		{
			BundleFile bundleFile = null;
			foreach(var bf in Uno.IO.Bundle.AllFiles)
			{
				if(bf.SourcePath == path)
				{
					bundleFile = bf;
					break;
				}
			}
			if (bundleFile != null)
				return bundleFile.BundlePath;
			else
				return "";
		}
	}
}