using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Controls.Native;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls
{
	extern(iOS) class TreeRenderer : ITreeRenderer
	{
		Action<ViewHandle> _setRoot;
		Action<ViewHandle> _clearRoot;

		public TreeRenderer(Action<ViewHandle> setRoot, Action<ViewHandle> clearRoot)
		{
			_setRoot = setRoot;
			_clearRoot = clearRoot;
		}

		readonly Dictionary<Element,ViewHandle> _elements = new Dictionary<Element,ViewHandle>();

		void ITreeRenderer.RootingStarted(Element e)
		{
			var v = InstantiateView(e);
			if (e is Control)
				((Control)e).ViewHandle = v;

			if (v.IsUIControl())
				Fuse.Controls.Native.iOS.InputDispatch.AddListener(e, v.HitTestHandle);

			if (e.Parent is Element && _elements.ContainsKey((Element)e.Parent))
				_elements[(Element)e.Parent].InsertChild(v, 0);
			else
				_setRoot(v);

			_elements.Add(e, v);
		}

		void ITreeRenderer.Rooted(Element e) { }

		void ITreeRenderer.Unrooted(Element e)
		{
			if (e.Parent is Element && _elements.ContainsKey((Element)e.Parent))
				_elements[(Element)e.Parent].RemoveChild(_elements[e]);
			else
				_clearRoot(_elements[e]);

			var v = _elements[e];
			_elements.Remove(e);

			if (v.IsUIControl())
				Fuse.Controls.Native.iOS.InputDispatch.RemoveListener(e, v.HitTestHandle);

			if (e is Control)
			{
				var c = (Control)e;
				if (c.ViewHandle != null)
				{
					c.ViewHandle.Dispose();
					c.ViewHandle = null;
				}
				c.NativeView = null;
			}
		}

		void ITreeRenderer.BackgroundChanged(Element e, Brush background)
		{
			_elements[e].SetBackgroundColor(background.GetColor());
		}

		void ITreeRenderer.TransformChanged(Element e)
		{
			var viewHandle = _elements[e];
			var transform = e.LocalTransform;

			var p = e.Parent;
			if (p is Control)
				((Control)p).CompensateForScrollView(ref transform);

			viewHandle.SetTransform(transform);
		}

		void ITreeRenderer.Placed(Element e)
		{
			_elements[e].SetSize(e.ActualSize);
		}

		void ITreeRenderer.IsVisibleChanged(Element e, bool isVisible)
		{
			_elements[e].SetIsVisible(isVisible);
		}

		void ITreeRenderer.IsEnabledChanged(Element e, bool isEnabled)
		{
			var v = _elements[e];
			v.SetEnabled(isEnabled);
		}

		void ITreeRenderer.OpacityChanged(Element e, float opacity)
		{
			_elements[e].SetOpacity(opacity);
		}

		void ITreeRenderer.ClipToBoundsChanged(Element e, bool clipToBounds)
		{
			_elements[e].SetClipToBounds(clipToBounds);
		}

		void ITreeRenderer.HitTestModeChanged(Element e, bool enabled)
		{
			var v = _elements[e];
			v.SetHitTestEnabled(enabled);
		}

		void ITreeRenderer.ZOrderChanged(Element e, List<Visual> zorder)
		{
			var len = zorder.Count;
			for (var i = 0; i < len; i++)
			{
				var child = e.GetZOrderChild(i) as Element;
				if (child != null)
					_elements[child].BringToFront();
			}
		}

		bool ITreeRenderer.Measure(Element e, LayoutParams lp, out float2 size)
		{
			var viewHandle = _elements[e];
			var canMeasure = viewHandle.IsLeafView;
			size = canMeasure
				? viewHandle.Measure(lp, e.Viewport.PixelsPerPoint)
				: float2(0.0f);
			return canMeasure;
		}

		ViewHandle InstantiateView(Element e)
		{
			ViewHandle result = null;
			var appearance = (InstantiateTemplate(e) ?? InstantiateViewOld(e)) as ViewHandle;
			if (appearance != null)
			{
				if (e is Control)
				{
					((Control)e).ViewHandle = appearance;
					if (appearance is IView)
						((Control)e).NativeView = (IView)appearance;
				}
				result = appearance;
			}
			else
			{
				result = ViewFactory.InstantiateViewGroup();
			}
			result.SetAccessibilityIdentifier(e.ToString());
			return result;
		}

		object InstantiateTemplate(Element e)
		{
			var t = e.FindTemplate("iOSAppearance");
			return t != null ? t.New() : null;
		}

		// For backwardscompatibility with old pattern
		object InstantiateViewOld(Element e)
		{
			if (e is Control)
			{
				var c = (Control)e;
				return c.InstantiateNativeView();
			}
			return null;
		}

	}

	extern(iOS) static class Extensions
	{
		public static float4 GetColor(this Brush brush)
		{
			var c = float4(0);
			if (brush != null)
			{
				var sc = brush as Fuse.Drawing.SolidColor;
				if (sc != null)
					c = sc.Color;
				var ssc = brush as Fuse.Drawing.StaticSolidColor;
				if (ssc != null)
					c = ssc.Color;

				if (sc == null && ssc == null)
					Fuse.Diagnostics.Unsupported( "Cannot convert to a color", brush );
			}
			return c;
		}
	}
}