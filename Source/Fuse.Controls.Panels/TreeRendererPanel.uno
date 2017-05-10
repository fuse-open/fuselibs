using Uno;
using Fuse;
using Fuse.Elements;
using Fuse.Controls.Native;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls
{
	internal interface INativeViewRoot
	{
		void Add(ViewHandle viewHandle);
		void Remove(ViewHandle viewHandle);
	}

	extern(Android || iOS) class TreeRendererPanel : Fuse.Controls.Panel
	{
		public override VisualContext VisualContext
		{
			get { return VisualContext.Native; }
		}

		public override ITreeRenderer TreeRenderer { get { return _treeRenderer; } }

		TreeRenderer _treeRenderer;
		INativeViewRoot _nativeViewHost;

		public TreeRendererPanel(INativeViewRoot nativeViewHost)
		{
			_nativeViewHost = nativeViewHost;
			_treeRenderer = new TreeRenderer(SetRoot, ClearRoot);
		}

		void SetRoot(ViewHandle viewHandle)
		{
			_nativeViewHost.Add(viewHandle);
		}

		void ClearRoot(ViewHandle viewHandle)
		{
			_nativeViewHost.Remove(viewHandle);
		}
	}
}
