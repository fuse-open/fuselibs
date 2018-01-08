using Uno;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Drawing;
using Fuse.Resources;
using Fuse.Elements;

namespace Fuse.Controls.Native
{
	public interface IView : IDisposable {}

	public interface ILeafView : IView {}

	public interface IGraphicsView: IView
	{
		bool BeginDraw(int2 size);
		void EndDraw();
	}

	public interface ILabelView: ILeafView
	{
		string Text { set; }
	}

	public interface ITextView: ILeafView
	{
		string Value { set; }
		int MaxLength { set; }
		TextWrapping TextWrapping { set; }
		float LineSpacing { set; }
		float FontSize { set;}
		Font Font { set; }
		TextAlignment TextAlignment { set; }
		float4 TextColor { set; }
		TextTruncation TextTruncation { set; }
	}

	public interface ITextEditHost
	{
		void OnValueChanged(string newValue);
		bool OnInputAction(TextInputActionType type);
		void OnFocusGained();
		void OnFocusLost();
	}

	public interface IToggleView
	{
		bool Value { set; }
	}

	public interface IToggleViewHost
	{
		void OnValueChanged(bool newValue);
	}

	public interface IRangeView
	{
		double Progress { set; }
	}

	public interface IRangeViewHost
	{
		void OnProgressChanged(double newProgress);
		double RelativeUserStep { get; }
	}

	public interface ITextEdit: ITextView
	{
		bool IsMultiline { set; }
		bool IsPassword { set; }
		bool IsReadOnly { set; }
		TextInputHint InputHint { set; }
		float4 CaretColor { set; }
		float4 SelectionColor { set; }
		TextInputActionStyle ActionStyle { set; }
		AutoCorrectHint AutoCorrectHint { set; }
		AutoCapitalizationHint AutoCapitalizationHint { set; }
		string PlaceholderText { set; }
		float4 PlaceholderColor { set; }
		void FocusGained();
		void FocusLost();
	}

	public interface IViewGroup : IView
	{
		void Add(IView child);
		void Add(IView child, int index);
		void Remove(IView child);
		bool ClipToBounds { set; }
		bool HitTestEnabled { set; }
	}

	public interface IImageView : IView
	{
		ImageSource ImageSource { set; }
		float4 TintColor { set; }
		void UpdateImageTransform(float density, float2 origin, float2 scale, float2 drawSize);
	}

	public interface IShapeView : IView
	{
		void Update(Brush[] fills, Stroke[] strokes, float pixelsPerPoint);
	}

	public interface IRectangleView : IShapeView
	{
		float4 CornerRadius { set; }
	}

	public interface ICircleView : IShapeView
	{
		float StartAngleDegrees { set; }
		float EndAngleDegrees { set; }
		float EffectiveEndAngleDegrees { set; }
		bool UseAngle { set; }
	}

	public interface IScrollView : IView
	{
		float2 ScrollPosition { set; }
		ScrollDirections AllowedScrollDirections { set; }
	}

	public interface IScrollViewHost
	{
		float PixelsPerPoint { get; }
		float2 ContentSize { get; }
		void OnScrollPositionChanged(float2 newScrollPosition);
	}

	public interface INativeViewRenderer : IDisposable
	{
		void Draw(float4x4 localToClipTransform, float2 position, float2 size, float density);
		void Invalidate();
	}

	public interface IViewHost
	{
		void Insert(ViewHandle child);
		void Remove(ViewHandle child);
	}

	public enum OffscreenRendering
	{
		Enabled,
		Disabled
	}

	public interface IOffscreenRendererHost
	{
		bool RenderToTexture { get; }
	}

	public interface IOffscreenRenderer : INativeViewRenderer
	{
		void EnableOffscreen();
		void DisableOffscreen();
	}

	extern(Android || iOS)
	internal static class ViewExtensions
	{
		extern(Android)
		public static Java.Object GetNativeHandle(this IView view)
		{
			if (view is Fuse.Controls.Native.Android.View)
				return ((Fuse.Controls.Native.Android.View)view).Handle;
			else
				throw new Exception(view + " is not a Fuse.Controls.Native.Android.View");
		}

		extern(iOS)
		public static ObjC.Object GetNativeHandle(this IView view)
		{
			if (view is Fuse.Controls.Native.iOS.View)
				return ((Fuse.Controls.Native.iOS.View)view).Handle;
			else
				throw new Exception(view + " is not a Fuse.Controls.Native.iOS.View");
		}
	}

}
