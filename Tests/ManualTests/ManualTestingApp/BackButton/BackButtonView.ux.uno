using Uno;

using Fuse;
using Fuse.Controls;
using Fuse.Elements;

using Uno.Platform;

public partial class BackButtonView 
{
	bool _passed = false;
	bool _handlerInitialized = false;

	void EnableBack(object s, object a)
	{
		_passed = false;
		_handlerInitialized = true;
		Uno.Platform.EventSources.HardwareKeys.KeyDown += OnKeyPressed;
		StatusLabelNotPassed.Visibility = Visibility.Visible;
		StatusLabelPassed.Visibility = Visibility.Collapsed;
	}

	void DisableBack(object s, object a)
	{
		if (_handlerInitialized)
		{
			_handlerInitialized = false;
			Uno.Platform.EventSources.HardwareKeys.KeyDown -= OnKeyPressed;
		}
	}

	void OnKeyPressed(object sender, Uno.Platform.KeyEventArgs args)
	{
		if (args.Key == Key.BackButton && !_passed)
		{
			_passed = true;
			StatusLabelPassed.Visibility = Visibility.Visible;
			StatusLabelNotPassed.Visibility = Visibility.Collapsed;
			args.Handled = true;
		}
	}
}
