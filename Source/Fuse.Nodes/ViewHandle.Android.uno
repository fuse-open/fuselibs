using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Controls.Native
{

	extern(!Android && !iOS)
	public class ViewHandle { }

	extern(Android)
	public class ViewHandle : IDisposable
	{
		public enum Invalidation
		{
			None,
			OnInvalidateVisual,
		}

		public readonly Java.Object NativeHandle;

		int2 _size = int2(0);
		internal int2 Size
		{
			get { return _size;}
			set
			{
				if (_size != value)
				{
					_size = value;
					OnSizeChanged();
				}
			}
		}

		internal readonly bool NeedsInvalidation;
		internal readonly bool IsLeafView;
		internal readonly bool HandlesInput;

		public ViewHandle(Java.Object nativeHandle) : this(nativeHandle, false, false) { }

		public ViewHandle(Java.Object nativeHandle, bool isLeafView) : this(nativeHandle, isLeafView, false) { }

		public ViewHandle(Java.Object nativeHandle, bool isLeafView, bool handlesInput) : this(nativeHandle, isLeafView, handlesInput, Invalidation.None) { }

		public ViewHandle(Java.Object nativeHandle, bool isLeafView, bool handlesInput, Invalidation invalidation)
		{
			NativeHandle = nativeHandle;
			IsLeafView = isLeafView;
			HandlesInput = handlesInput;
			NeedsInvalidation = invalidation == Invalidation.OnInvalidateVisual;
		}

		public virtual void Dispose() {}

		public override string ToString()
		{
			return "Fuse.Controls.Native.ViewHandle(" + Format() + ")";
		}

		internal protected virtual void OnSizeChanged() {}

		[Foreign(Language.Java)]
		public void SetClipToBounds(bool clipToBounds)
		@{
			android.view.View view = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			if (view instanceof android.view.ViewGroup)
			{
				android.view.ViewGroup viewGroup = (android.view.ViewGroup)view;
				viewGroup.setClipChildren(clipToBounds);
				viewGroup.setClipToPadding(clipToBounds);
			}
		@}

		public void ResetState()
		{
			ResetLayoutParams();
			SetOpacity(1.0f);
			SetEnabled(true);
			SetIsVisible(true);
			SetBackgroundColor(0);
			UpdateTransform(1.0f, 1.0f, 0.0f, 0.0f, 0.0f);
		}

		[Foreign(Language.Java)]
		public static void CopyState(ViewHandle sourceHandle, ViewHandle destHandle)
		@{
			android.view.View source = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(sourceHandle).NativeHandle:Get()};
			android.view.View dest = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(destHandle).NativeHandle:Get()};
			dest.setVisibility(source.getVisibility());
			dest.setEnabled(source.isEnabled());
			dest.setAlpha(source.getAlpha());
			dest.setBackgroundDrawable(source.getBackground());
			dest.setLayoutParams(source.getLayoutParams());
			dest.setPivotX(0);
			dest.setPivotY(0);
			dest.setScaleX(source.getScaleX());
			dest.setScaleY(source.getScaleY());
			dest.setRotation(source.getRotation());
			dest.setRotationX(source.getRotationX());
			dest.setRotationY(source.getRotationY());
		@}

		[Foreign(Language.Java)]
		public void ResetLayoutParams()
		@{
			((android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
		@}

		[Foreign(Language.Java)]
		public void SetBackgroundColor(int color)
		@{
			android.view.View view = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			view.setBackgroundColor(color);
		@}

		[Foreign(Language.Java)]
		public void SetOpacity(float value)
		@{
			((android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).setAlpha(value);
		@}

		[Foreign(Language.Java)]
		public void SetEnabled(bool value)
		@{
			((android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()}).setEnabled(value);
		@}

		[Foreign(Language.Java)]
		public void SetIsVisible(bool isVisible)
		@{
			android.view.View handle = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			handle.setVisibility( (isVisible) ? android.view.View.VISIBLE : android.view.View.INVISIBLE );
		@}

		[Foreign(Language.Java)]
		void InvalidateImpl()
		@{
			android.view.View handle = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			handle.invalidate();
		@}

		public void Invalidate()
		{
			if (NeedsInvalidation)
				InvalidateImpl();
		}

		[Foreign(Language.Java)]
		public string Format()
		@{
			java.lang.Object handle = @{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			return handle.toString();
		@}

		public void UpdateViewRect(float4x4 transform, float2 size, float density)
		{
			float3 scale;
			float4 rotation;
			float3 translation;

			Matrix.Decompose(transform, out scale, out rotation, out translation);

			var r = Quaternion.ToEulerAngleDegrees(rotation).XYZ;

			var actualPosition = (int2)(translation.XY * density);
			var actualSize = Size = (int2)(size * density);

			UpdateTransform(scale.X, scale.Y, r.Z, r.X, r.Y);
			UpdateViewRect(actualPosition.X, actualPosition.Y, actualSize.X, actualSize.Y);
		}

		[Foreign(Language.Java)]
		public bool IsViewGroup()
		@{
			java.lang.Object handle = @{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			return handle instanceof com.fuse.android.views.ViewGroup ||
				handle instanceof com.fuse.android.views.FuseScrollView;
		@}

		[Foreign(Language.Java)]
		public void SetHitTestEnabled(bool enabled)
		@{
			android.view.View view = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			if (view instanceof com.fuse.android.views.ViewGroup) {
				com.fuse.android.views.ViewGroup viewgroup = (com.fuse.android.views.ViewGroup)view;
				viewgroup.HitTestEnabled = enabled;
			}
		@}

		[Foreign(Language.Java)]
		public void InsertChild(ViewHandle childHandle)
		@{
			android.view.ViewGroup parent = (android.view.ViewGroup)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			android.view.View child = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(childHandle).NativeHandle:Get()};
			parent.addView(child);
		@}

		[Foreign(Language.Java)]
		public void InsertChild(ViewHandle childHandle, int index)
		@{
			android.view.ViewGroup parent = (android.view.ViewGroup)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			android.view.View child = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(childHandle).NativeHandle:Get()};
			parent.addView(child, index);
		@}

		[Foreign(Language.Java)]
		public void RemoveChild(ViewHandle childHandle)
		@{
			android.view.ViewGroup parent = (android.view.ViewGroup)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			android.view.View child = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(childHandle).NativeHandle:Get()};
			parent.removeView(child);
		@}

		[Foreign(Language.Java)]
		public int IndexOfChild(ViewHandle childHandle)
		@{
			android.view.ViewGroup parent = (android.view.ViewGroup)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			android.view.View child = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(childHandle).NativeHandle:Get()};
			return parent.indexOfChild(child);
		@}

		[Foreign(Language.Java)]
		public void BringToFront()
		@{
			android.view.View view = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			view.bringToFront();
		@}

		public void UpdateViewRect(int x, int y, int w, int h)
		{
			Size = int2(w, h);
			UpdateViewRectImpl(x, y, w, h);
		}

		[Foreign(Language.Java)]
		void UpdateViewRectImpl(int x, int y, int w, int h)
		@{
			android.view.View view = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			com.fuse.android.views.ViewGroup.UpdateChildRect(view, x, y, w, h);
		@}

		[Foreign(Language.Java)]
		public void UpdateTransform(
			float scaleX,
			float scaleY,
			float rotation,
			float rotationX,
			float rotationY)
		@{
			android.view.View view = (android.view.View)@{Fuse.Controls.Native.ViewHandle:Of(_this).NativeHandle:Get()};
			view.setPivotX(0);
			view.setPivotY(0);
			view.setScaleX(scaleX);
			view.setScaleY(scaleY);
			view.setRotation(rotation);
			view.setRotationX(rotationX);
			view.setRotationY(rotationY);
		@}

		public virtual float2 Measure(LayoutParams lp, float density)
		{
			var handle = NativeHandle;
			Measure(handle, (int)(lp.X * density), (int)(lp.Y * density), lp.HasX, lp.HasY);
			var res = float2(GetMeasuredWidth(handle) / density, GetMeasuredHeight(handle) / density);
			return res;
		}

		[Foreign(Language.Java)]
		static void Measure(Java.Object handle, int w, int h, bool hasX, bool hasY)
		@{
			int wSpec = hasX ? android.view.View.MeasureSpec.makeMeasureSpec(w, android.view.View.MeasureSpec.EXACTLY) : 0;
			int hSpec = hasY ? android.view.View.MeasureSpec.makeMeasureSpec(h, android.view.View.MeasureSpec.EXACTLY) : 0;
			android.view.View view = (android.view.View)handle;
			view.measure(wSpec, hSpec);
		@}

		[Foreign(Language.Java)]
		static int GetMeasuredWidth(Java.Object handle)
		@{
			return ((android.view.View)handle).getMeasuredWidth();
		@}

		[Foreign(Language.Java)]
		static int GetMeasuredHeight(Java.Object handle)
		@{
			return ((android.view.View)handle).getMeasuredHeight();
		@}
	}

	extern(Android) internal static class ViewFactory
	{
		public static ViewHandle InstantiateViewGroup()
		{
			return new ViewHandle(InstantiateViewGroupImpl(), false);
		}

		[Foreign(Language.Java)]
		static Java.Object InstantiateViewGroupImpl()
		@{
			android.widget.FrameLayout frameLayout = new com.fuse.android.views.ViewGroup(com.fuse.Activity.getRootActivity());
			frameLayout.setFocusable(true);
			frameLayout.setFocusableInTouchMode(true);
			frameLayout.setClipChildren(false);
			frameLayout.setClipToPadding(false);
			frameLayout.setLayoutParams(new android.widget.FrameLayout.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));
			return frameLayout;
		@}
	}
}
