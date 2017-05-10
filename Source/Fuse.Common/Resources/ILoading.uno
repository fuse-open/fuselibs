using Uno;
using Uno.UX;

namespace Fuse
{
	/**
		Marks non-Node classes as having a loading state.
	*/
	interface ILoading
	{
		bool IsLoading { get; }
	}
	
	static class ILoadingStatic
	{
		static public Selector IsLoadingName = "IsLoading";
	}
}
