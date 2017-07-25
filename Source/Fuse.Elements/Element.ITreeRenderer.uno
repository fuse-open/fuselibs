using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Elements;
using Fuse.Drawing;

namespace Fuse.Elements
{
	public interface ITreeRenderer
	{
		void RootingStarted(Element e);
		void Rooted(Element e);
		void Unrooted(Element e);
		void BackgroundChanged(Element e, Brush background);
		void TransformChanged(Element e);
		void Placed(Element e);
		void IsVisibleChanged(Element e, bool isVisible);
		void IsEnabledChanged(Element e, bool isEnabled);
		void OpacityChanged(Element e, float opacity);
		void ClipToBoundsChanged(Element e, bool clipToBounds);
		void ZOrderChanged(Element e, Visual[] zorder);
		void HitTestModeChanged(Element e, bool enabled);
		bool Measure(Element e, LayoutParams lp, out float2 size);
	}

	public partial class Element
	{
		public virtual ITreeRenderer TreeRenderer
		{
			get { return Parent	is Element ? ((Element)Parent).TreeRenderer : null; }
		}

		protected override void OnIsVisibleChanged()
		{
			base.OnIsVisibleChanged();
			if (IsRootingCompleted)
			{
				var t = TreeRenderer;
				if (t != null)
					t.IsVisibleChanged(this, IsVisible);
			}
		}

		bool _dispatchedZOrderChanged; // This can happen a lot, so avoid multiple dispatch
		void NotifyTreeRendererZOrderChanged()
		{
			if (HasChildren && !_dispatchedZOrderChanged)
			{
				_dispatchedZOrderChanged = true;
				UpdateManager.AddDeferredAction(OnZOrderChanged, UpdateStage.Layout, LayoutPriority.Post);
			}
		}

		void OnZOrderChanged()
		{
			_dispatchedZOrderChanged = false;
			if (IsRootingCompleted)
			{
				var t = TreeRenderer;
				if (t != null)
					t.ZOrderChanged(this, GetCachedZOrder());
			}
		}

		bool _transformChanged = false;
		void NotifyTreeRendererTransformChanged()
		{
			if (!_transformChanged)
			{
				UpdateManager.AddDeferredAction(SetNewTransform, UpdateStage.Layout, LayoutPriority.Post);
				_transformChanged = true;
			}
		}

		void SetNewTransform()
		{
			if (IsRootingCompleted)
			{
				var t = TreeRenderer;
				if (t != null)
					t.TransformChanged(this);
			}
			_transformChanged = false;
		}

		void NotifyTreeRendererHitTestModeChanged()
		{
			if (IsRootingCompleted)
			{
				var t = TreeRenderer;
				if (t != null)
					t.HitTestModeChanged(this, HitTestMode != Fuse.Elements.HitTestMode.None);
			}
		}

		void NotifyTreeRedererOpacityChanged()
		{
			if (IsRootingCompleted)
			{
				var t = TreeRenderer;
				if (t != null)
					t.OpacityChanged(this, Opacity);
			}
		}

		protected override void OnIsContextEnabledChanged()
		{
			base.OnIsContextEnabledChanged();
			if (IsRootingCompleted)
			{
				var t = TreeRenderer;
				if (t != null)
					t.IsEnabledChanged(this, IsEnabled);
			}
		}

		internal protected override void OnRootedPreChildren()
		{
			NotifyTreeRendererRootingStarted();
			base.OnRootedPreChildren();
		}

		void NotifyTreeRendererRootingStarted()
		{
			var t = TreeRenderer;
			if (t != null)
				t.RootingStarted(this);
		}

		void NotifyTreeRendererRooted()
		{
			var t = TreeRenderer;
			if (t != null)
			{
				t.Rooted(this);
				t.OpacityChanged(this, Opacity);
				t.IsVisibleChanged(this, IsVisible);
				t.IsEnabledChanged(this, IsEnabled);
				t.ClipToBoundsChanged(this, ClipToBounds);
				t.HitTestModeChanged(this, HitTestMode != Fuse.Elements.HitTestMode.None);
				if (HasChildren)
					t.ZOrderChanged(this, GetCachedZOrder());
			}
		}

		void NotifyTreeRendererUnrooted()
		{
			var t = TreeRenderer;
			if (t != null)
				TreeRenderer.Unrooted(this);
		}
	}
}
