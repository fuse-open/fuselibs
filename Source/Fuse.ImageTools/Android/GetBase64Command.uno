extern (Android) class GetBase64Command : PCommand {
	string _path;
	Action<string> _resolve;
	Action<string> _reject;
	public GetBase64Command(string path, Action<string> Resolve, Action<string> Reject) : base(new PlatformPermission[] { Permissions.Android.READ_EXTERNAL_STORAGE })
	{
		_path = path;
		_resolve = Resolve;
		_reject = Reject;
	}
	override void OnGranted()
	{
		AndroidImageUtils.GetBase64FromImage(_path, _resolve, _reject);
	}

	override void OnRejected(Exception e)
	{
		_reject(e.Message);
	}
}
