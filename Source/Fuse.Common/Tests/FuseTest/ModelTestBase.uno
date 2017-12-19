using Uno;

namespace FuseTest
{
	/** 
		USe this base for tests that use Models. It does some registration of needed global modules.
	*/
	public class ModelTestBase : TestBase
	{
		public ModelTestBase()
		{
			RequireModule<global::Fuse.Reactive.FuseJS.DiagnosticsImplModule>();
			RequireModule<global::Fuse.Reactive.FuseJS.Http>();
			RequireModule<global::Fuse.Reactive.FuseJS.TimerModule>();
			RequireModule<global::Fuse.Storage.StorageModule>();
			RequireModule<global::Fuse.Drawing.BrushConverter>();
			RequireModule<global::Fuse.Triggers.BusyTaskModule>();
			RequireModule<global::Fuse.WebSocket.WebSocketClientModule>();
			RequireModule<global::Polyfills.Window.WindowModule>();
			RequireModule<global::FuseJS.Globals>();
			RequireModule<global::FuseJS.Lifecycle>();
			RequireModule<global::FuseJS.Environment>();
			RequireModule<global::FuseJS.Base64>();
			RequireModule<global::FuseJS.Bundle>();
			RequireModule<global::FuseJS.FileReaderImpl>();
			RequireModule<global::FuseJS.UserEvents>();
		}
	}
}
