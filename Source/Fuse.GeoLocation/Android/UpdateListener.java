package fuse.geolocation;
import android.location.Location;
import android.location.LocationManager;
import com.foreign.Uno.Action_Object;

public class UpdateListener implements android.location.LocationListener{

  Action_Object _onLocationChanged;

  public UpdateListener(Action_Object onLocationChanged)
  {
    _onLocationChanged = onLocationChanged;
  }

  public void	onLocationChanged(Location location)
  {
    _onLocationChanged.run(location);
  }

  public void	onProviderDisabled(String provider)
  {
  }

  public void	onProviderEnabled(String provider)
  {
  }

  public void	onStatusChanged(String provider, int status, android.os.Bundle extras)
  {
  }
}
