using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Primitives;
using Fuse.Effects;
using Fuse.Elements;

namespace Fuse.Controls
{
	/** Draws a shadow behind an element.

		## Example

		This example shows a rounded rectangle with a shadow that animates in size when pressed:
		```xml
			<Rectangle Width="100" Height="100" Color="Red" CornerRadius="5">
				<Shadow ux:Name="RectangleShadow" Size="10" />
				<Clicked>
					<Change DurationBack="0.2" RectangleShadow.Size="20" />
				</Clicked>
			</Rectangle>
		```
	*/
	public class Shadow : Behavior
	{
		/** Controls how Shadow is drawn. */
		public enum ShadowMode
		{
			/** Draw a smoothed rectangle below the area the element-background covers. */
			Background,
			/** Capture the alpha-mask and blur it, similar to what `DropShadow` does. */
			PerPixel
		}

		// details about parent
		Element _elementParent;

		// shadow implementation
		DropShadow _dropShadow;
		ShadowElement _rectangle;
		Translation _rectangleTranslation;

		ShadowMode _mode = ShadowMode.Background;
		/** The [ShadowMode](api:fuse/controls/shadow/shadowmode) used for drawing the shadow. */
		public ShadowMode Mode
		{
			get
			{
				return _mode;
			}

			set
			{
				if (_mode != value)
				{
					if (IsRootingCompleted)
						RemoveDecoration();

					_mode = value;

					if (IsRootingCompleted)
						AddDecoration();
				}
			}
		}

		public Shadow()
		{
			Size = 5;
			Color = float4(0, 0, 0, 0.35f);
			Angle = 90;
			Distance = 3;
		}


		float _angle;
		/** The angle, in degrees, at which light is hitting the element. */
		public float Angle
		{
			get { return _angle; }
			set
			{
				_angle = value;

				if (_dropShadow != null)
					_dropShadow.Angle = value;

				if (_rectangleTranslation != null)
					_rectangleTranslation.XY = Offset;

				if (_elementParent != null && _elementParent.ViewHandle != null)
					DecorateNativeShadow(Color, Size, Offset);
			}
		}

		float _distance;
		/** The distance in points the shadow should be offset from its source. */
		public float Distance
		{
			get { return _distance; }
			set
			{
				_distance = value;

				if (_dropShadow != null)
					_dropShadow.Distance = value;

				if (_rectangleTranslation != null)
					_rectangleTranslation.XY = Offset;

				if (_elementParent != null && _elementParent.ViewHandle != null)
					DecorateNativeShadow(Color, Size, Offset);
			}
		}

		float2 Offset
		{
			get
			{
				float th = Angle * (Math.PIf / 180);
				return float2(-Math.Cos(th), Math.Sin(th)) * Distance;
			}
		}

		float _size;
		/** The size of the shadow, in points. */
		public float Size
		{
			get { return _size; }
			set
			{
				_size = value;

				if (_rectangle != null)
					_rectangle.ShadowSize = _size;

				if (_dropShadow != null)
					_dropShadow.Size = _size;

				if (_elementParent != null && _elementParent.ViewHandle != null)
					DecorateNativeShadow(Color, Size, Offset);
			}
		}

		float4 _color;
		/**
			The color of the drop shadow.

			For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		public float4 Color
		{
			get { return _color; }
			set
			{
				_color = value;

				if (_rectangle != null)
					_rectangle.Color = _color;

				if (_dropShadow != null)
					_dropShadow.Color = _color;

				if (_elementParent != null && _elementParent.ViewHandle != null)
					DecorateNativeShadow(Color, Size, Offset);
			}
		}

		void AddDecoration()
		{
			switch (_mode)
			{
				case ShadowMode.Background:
					if (_rectangle != null)
						throw new Exception("Invalid rectangle-state");

					_rectangle = new ShadowElement
					{
						Layer = Layer.Underlay,
						Width = new Size(100, Unit.Percent),
						Height = new Size(100, Unit.Percent),
						Color = _color,
						ShadowSize = _size
					};

					// TODO: move into ShadowElement?
					_rectangleTranslation = new Translation();
					_rectangleTranslation.XY = Offset;
					_rectangle.Children.Add(_rectangleTranslation);

					_elementParent.InsertAfter(this, _rectangle);
					break;

				case ShadowMode.PerPixel:
					if (_dropShadow != null)
						throw new Exception("Invalid dropshadow-state");

					_dropShadow = new DropShadow
					{
						Color = _color,
						Size = _size,
						Angle = _angle,
						Distance = _distance
					};
					_elementParent.InsertAfter(this, _dropShadow);
					break;
			}
		}

		void RemoveDecoration()
		{
			switch (_mode)
			{
				case ShadowMode.Background:
					if (_rectangle == null)
						throw new Exception("Invalid rectangle-state");

					_elementParent.Children.Remove(_rectangle);
					_rectangle = null;
					_rectangleTranslation = null;
					break;

				case ShadowMode.PerPixel:
					if (_dropShadow == null)
						throw new Exception("Invalid rectangle-state");

					_elementParent.Children.Remove(_dropShadow);
					_dropShadow = null;
					break;
			}
		}

		void AddNativeDecoration()
		{
			DecorateNativeShadow(Color, Size, Offset);
		}

		void DecorateNativeShadow(float4 color, float size, float2 offset)
		{
			if defined(iOS)
				AddDecorationInternalIOS(_elementParent.ViewHandle.NativeHandle, color, size, offset);
			if defined(Android)
				AddDecorationInternalAndroid(_elementParent.ViewHandle.NativeHandle, (int)Uno.Color.ToArgb(color), size, offset.X, offset.Y);
		}

		[Foreign(Language.ObjC)]
		static extern (iOS) void AddDecorationInternalIOS(ObjC.Object viewHandle, float4 color, float size, float2 offset)
		@{
			UIView * view = (UIView *)viewHandle;
			view.layer.masksToBounds = NO;
			view.layer.shadowColor = [UIColor colorWithRed:color.X green:color.Y blue:color.Z alpha:color.W].CGColor;
			view.layer.shadowOpacity = 1.0;
			view.layer.shadowRadius = size;
			view.layer.shadowOffset = CGSizeMake(offset.X, offset.Y);
			view.layer.shouldRasterize = YES;
			view.layer.rasterizationScale = [UIScreen mainScreen].scale;
		@}

		[Foreign(Language.Java)]
		static extern (Android) void AddDecorationInternalAndroid(Java.Object viewHandle, int color, float size, float offsetX, float offsetY)
		@{
			if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
				android.view.View view = (android.view.View)viewHandle;
				android.view.ViewGroup parentView = (android.view.ViewGroup)view.getParent();
				if (parentView != null)
					parentView.setClipToPadding(false);
				float scale = com.fuse.Activity.getRootActivity().getResources().getDisplayMetrics().density;
				float elevationSize = (size * scale + 0.5f);
				view.setElevation(elevationSize);
				view.setOutlineProvider(new android.view.ViewOutlineProvider() {
					@Override
					public void getOutline(android.view.View view, android.graphics.Outline outline) {
						if (view.getBackground() != null) {
							android.graphics.Rect rect = view.getBackground().copyBounds();
							rect.offset((int) offsetX, (int) offsetY);
							outline.setRect(rect);
						}
					}
				});
				view.setOutlineAmbientShadowColor(color);
				view.setOutlineSpotShadowColor(color);
			}
		@}

		void RemoveNativeDecoration()
		{
			if defined(MOBILE)
			{
				var viewhandle = _elementParent.ViewHandle;
				RemoveDecorationInternal(viewhandle.NativeHandle);
			}
		}

		[Foreign(Language.ObjC)]
		static extern(iOS) void RemoveDecorationInternal(ObjC.Object viewHandle)
		@{
			UIView * view = (UIView *)viewHandle;
			view.layer.shadowColor = nil;
			view.layer.shadowOpacity = 0;
			view.layer.shadowRadius = 0;
			view.layer.shadowOffset = CGSizeMake(0, 0);
		@}

		[Foreign(Language.Java)]
		static extern(Android) void RemoveDecorationInternal(Java.Object viewHandle)
		@{
			if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
				android.view.View view = (android.view.View)viewHandle;
				android.view.ViewGroup parentView = (android.view.ViewGroup)view.getParent();
				if (parentView != null)
					parentView.setClipToPadding(true);
				view.setOutlineProvider(android.view.ViewOutlineProvider.BACKGROUND);
				view.setElevation(0);
				view.setOutlineAmbientShadowColor(android.graphics.Color.TRANSPARENT);
				view.setOutlineSpotShadowColor(android.graphics.Color.TRANSPARENT);
			}
		@}

		protected override void OnRooted()
		{
			base.OnRooted();

			_elementParent = Parent as Element;
			if (_elementParent == null)
				throw new Exception("Invalid parent for Effect: " + Parent);

			if (_elementParent.ViewHandle != null)
				AddNativeDecoration();
			else
				AddDecoration();
		}

		protected override void OnUnrooted()
		{
			if (_elementParent.ViewHandle != null)
				RemoveNativeDecoration();
			else
				RemoveDecoration();
			_elementParent = null;
			base.OnUnrooted();
		}
	}
}
