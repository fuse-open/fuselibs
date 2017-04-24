using Uno;

using Fuse;
using Fuse.Drawing;

namespace FuseTest
{
	/**
		A test brush that reports it is loading, and can also complete the loading.
	*/
	public class LoadingBrush : DynamicBrush, ILoading
	{
		bool _isLoading = true;
		public bool IsLoading 
		{ 
			get { return _isLoading; }
			set
			{
				_isLoading = false;
				OnPropertyChanged(ILoadingStatic.IsLoadingName);
			}
		}
		
		bool ILoading.IsLoading
		{
			get { return IsLoading; }
		}
	}
}
