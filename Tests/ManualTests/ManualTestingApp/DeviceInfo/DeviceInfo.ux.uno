using Uno;
using OpenGL;

public partial class DeviceInfo
{
	public DeviceInfo()
	{
		InitializeUX();

		_fuselibsVersionNumberText.Value = string.Format("{0}.{1}.{2}", Fuse.Version.Major, Fuse.Version.Minor, Fuse.Version.Patch);
		_fuselibsFullVersionText.Value = Fuse.Version.String;

		if defined(OpenGL)
		{
			_glesVersionText.Value = GL.GetString(GLStringName.Version);
			_glesVendorText.Value = GL.GetString(GLStringName.Vendor);
			_glesRendererText.Value = GL.GetString(GLStringName.Renderer);
		}
	}
}
