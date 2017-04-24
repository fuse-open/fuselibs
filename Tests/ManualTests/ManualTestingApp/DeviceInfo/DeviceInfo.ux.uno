using Uno;
using OpenGL;

public partial class DeviceInfo
{
	public DeviceInfo()
	{
		InitializeUX();

		if defined(MOBILE)
		{
			var display = Uno.Platform.Displays.MainDisplay;
			var size = Fuse.Platform.SystemUI.Frame.Size;
			var density = display.Density;
			_resolutionText.Value = size.X.ToString() + " x " + size.Y.ToString();
			_densityText.Value = density.ToString();
		}

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
