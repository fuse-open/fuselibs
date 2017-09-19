extern (Android) class ImageFromBase64Command : PCommand {
	string _base64Image;
	Action<string> _resolve;
	Action<string> _reject;
	public ImageFromBase64Command(string base64Image, Action<string> Resolve, Action<string> Reject) : base(new PlatformPermission[] { Permissions.Android.WRITE_EXTERNAL_STORAGE })
	{
		_base64Image = base64Image;
		_resolve = Resolve;
		_reject = Reject;
	}
	override void OnGranted()
	{
		AndroidImageUtils.GetImageFromBase64(_base64Image, _resolve, _reject);
	}

	override void OnRejected(Exception e)
	{
		_reject(e.Message);
	}
}
