using Uno.Permissions;
using Fuse.Scripting;
using Uno;
namespace Fuse.ImageTools
{
  // I hate everything to do with this
  internal abstract extern(Android) class PCommand
  {
    PlatformPermission[] _requiredPermissions;

    public PCommand(PlatformPermission[] requiredPermissions)
    {
      _requiredPermissions = requiredPermissions;
    }

    public void Execute()
    {
      if defined(Android)
      {
        Permissions.Request(_requiredPermissions).Then(OnPermissions, OnRejected);
      }
      else
      {
        OnGranted();
      }
    }

    void OnPermissions(PlatformPermission[] grantedPermissions)
    {
      if(grantedPermissions.Length!=_requiredPermissions.Length)
      {
        OnRejected(new Exception("Required permission(s) not granted."));
      }
      else
      {
        OnGranted();
      }
    }

    abstract void OnGranted();
    abstract void OnRejected(Exception e);
  }

  extern (Android) class ResizeCommand : PCommand {
    string _path;
    int _desiredWidth;
    int _desiredHeight;
    int _mode;
    bool _inPlace;
    Action<string> _resolve;
    Action<string> _reject;
    public ResizeCommand(string path, int desiredWidth, int desiredHeight, int mode, Action<string> Resolve, Action<string> Reject, bool inPlace) : base(new PlatformPermission[] { Permissions.Android.READ_EXTERNAL_STORAGE, Permissions.Android.WRITE_EXTERNAL_STORAGE })
    {
      _path = path;
      _desiredWidth = desiredWidth;
      _desiredHeight = desiredHeight;
      _mode = mode;
      _inPlace = inPlace;
      _resolve = Resolve;
      _reject = Reject;
    }
    override void OnGranted()
    {
      AndroidImageUtils.Resize(_path, _desiredWidth, _desiredHeight, _mode, _resolve, _reject, _inPlace);
    }

    override void OnRejected(Exception e)
    {
      _reject(e.Message);
    }
  }

  extern (Android) class CropCommand : PCommand {
    string _path;
    int _x;
    int _y;
    int _width;
    int _height;
    bool _inPlace;
    Action<string> _resolve;
    Action<string> _reject;
    public CropCommand(string path, int x, int y, int desiredWidth, int desiredHeight, Action<string> Resolve, Action<string> Reject, bool inPlace) : base(new PlatformPermission[] { Permissions.Android.READ_EXTERNAL_STORAGE, Permissions.Android.WRITE_EXTERNAL_STORAGE })
    {
      _path = path;
      _x = x;
      _y = y;
      _width = desiredWidth;
      _height = desiredHeight;
      _resolve = Resolve;
      _reject = Reject;
      _inPlace = inPlace;
    }
    override void OnGranted()
    {
      AndroidImageUtils.Crop(_path, _x, _y, _width, _height, _resolve, _reject, _inPlace);
    }

    override void OnRejected(Exception e)
    {
      _reject(e.Message);
    }
  }

}
