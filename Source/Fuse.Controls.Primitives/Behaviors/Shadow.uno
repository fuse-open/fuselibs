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
	public class Shadow : Behavior, IPropertyListener
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

		Fuse.Controls.ShadowImpl androidShadow;
		void DecorateNativeShadow(float4 color, float size, float2 offset)
		{
			if defined(iOS)
			{
				AddDecorationInternalIOS(_elementParent.ViewHandle.NativeHandle, color, size, offset);
			}
			if defined(Android)
			{
				if (androidShadow == null)
					androidShadow = new Fuse.Controls.ShadowImpl(_elementParent.ViewHandle.NativeHandle, (int)Uno.Color.ToArgb(color), size, offset.X, offset.Y);
				androidShadow.Color = (int)Uno.Color.ToArgb(color);
				androidShadow.Size = (int)size;
				androidShadow.OffsetX = (int)offset.X;
				androidShadow.OffsetY = (int)offset.Y;
				var rectangle = _elementParent as Rectangle;
				if (rectangle != null)
					androidShadow.SetCornerRadius(rectangle.CornerRadius);
				var circle  = _elementParent as Circle;
				if (circle != null)
					androidShadow.IsCircle(true);
			}
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

		void RemoveNativeDecoration()
		{
			if defined(iOS)
			{
				var viewhandle = _elementParent.ViewHandle;
				RemoveDecorationInternal(viewhandle.NativeHandle);
			}
			if defined(Android)
			{
				androidShadow.ClearShadow();
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

		protected override void OnRooted()
		{
			base.OnRooted();

			_elementParent = Parent as Element;
			if (_elementParent == null)
				throw new Exception("Invalid parent for Effect: " + Parent);

			if (_elementParent.ViewHandle != null)
			{
				UpdateManager.AddDeferredAction(AddNativeDecoration, UpdateStage.Layout, LayoutPriority.Post);
				_elementParent.AddPropertyListener(this);
			}
			else
				AddDecoration();
		}

		protected override void OnUnrooted()
		{
			if (_elementParent.ViewHandle != null)
			{
				RemoveNativeDecoration();
				_elementParent.RemovePropertyListener(this);
			}
			else
				RemoveDecoration();
			_elementParent = null;
			base.OnUnrooted();
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if defined(Android)
			{
				if (_elementParent != null)
				{
					if (prop == Panel.ColorPropertyName)
						if (androidShadow != null)
							androidShadow.SetupShadow();

					if (prop == Rectangle.CornerRadiusPropertyName)
						if (androidShadow != null)
						{
							var rectangle = _elementParent as Rectangle;
							androidShadow.SetCornerRadius(rectangle.CornerRadius);
						}
				}
			}
		}
	}

	extern(!Android) class ShadowImpl
	{
		public ShadowImpl(int color, float size, float offsetX, float offsetY) { }
	}

	extern(Android) class ShadowImpl {

		Java.Object viewHandle;
		Java.Object shadowDrawable;
		string pathData = "";

		public ShadowImpl(Java.Object viewHandle, int color, float size, float offsetX, float offsetY)
		{
			this.viewHandle = viewHandle;
			this.shadowDrawable = CreateShadowDrawable(color, size, offsetX, offsetY);
			SetupShadow();
		}

		public int Color
		{
			get { return GetColor(); }
			set { SetColor(value); }
		}

		public int Size
		{
			get { return GetSize(); }
			set { SetSize(value); }
		}

		public int OffsetX
		{
			get { return GetOffsetX(); }
			set { SetOffsetX(value); }
		}

		public int OffsetY
		{
			get { return GetOffsetY(); }
			set { SetOffsetY(value); }
		}

		public void IsCircle(bool circle)
		{
			SetCircle(true);
		}

		public void SetPathData(string pathData)
		{
			this.pathData = pathData;
		}

		public void SetCornerRadius(float4 cornerRadius)
		{
			var numbers = new float[] { cornerRadius.X, cornerRadius.X, cornerRadius.Y, cornerRadius.Y, cornerRadius.Z, cornerRadius.Z, cornerRadius.W, cornerRadius.W };
			ChangeCornerRadius(numbers);
		}

		[Foreign(Language.Java)]
		public void SetupShadow()
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			android.view.View view = (android.view.View)@{ShadowImpl:of(_this).viewHandle:get()};
			String pathdata = @{ShadowImpl:of(_this).pathData:get()};
			android.graphics.drawable.Drawable background = view.getBackground();
			if (background != null)
			{
				android.graphics.drawable.Drawable[] layers = new android.graphics.drawable.Drawable[2];
				layers[0] = shadowDrawable;
				layers[1] = background;
				android.graphics.drawable.LayerDrawable layerDrawable = new android.graphics.drawable.LayerDrawable(layers);
				view.setBackground(layerDrawable);
			}
			else
				view.setBackground(shadowDrawable);
		@}

		[Foreign(Language.Java)]
		public void ClearShadow()
		@{
			android.view.View view = (android.view.View)@{ShadowImpl:of(_this).viewHandle:get()};
			android.graphics.drawable.Drawable background = view.getBackground();
			if (background instanceof android.graphics.drawable.LayerDrawable)
			{
				android.graphics.drawable.Drawable origBackground = ((android.graphics.drawable.LayerDrawable) background).getDrawable(1);
				view.setBackground(origBackground);
			} else
			{
				view.setBackground(null);
			}
		@}

		[Foreign(Language.Java)]
		public void ChangeCornerRadius(float[] radius)
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			shadowDrawable.setCornerRadius(radius.copyArray());
		@}

		[Foreign(Language.Java)]
		public void SetCircle(bool circle)
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			shadowDrawable.setCircle(circle);
		@}

		[Foreign(Language.Java)]
		private Java.Object CreateShadowDrawable(int color, float size, float offsetX, float offsetY)
		@{
			return new com.fuse.android.graphics.ShadowDrawable(com.fuse.Activity.getRootActivity(), color, (int)offsetX, (int) offsetY, (int)size);
		@}

		[Foreign(Language.Java)]
		public void SetColor(int color)
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			shadowDrawable.setColor(color);
		@}

		[Foreign(Language.Java)]
		public int GetColor()
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			return shadowDrawable.getColor();
		@}

		[Foreign(Language.Java)]
		public void SetSize(int size)
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			shadowDrawable.setSize(size);
		@}

		[Foreign(Language.Java)]
		public int GetSize()
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			return shadowDrawable.getSize();
		@}

		[Foreign(Language.Java)]
		public void SetOffsetX(int offsetX)
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			shadowDrawable.setOffsetX(offsetX);
		@}

		[Foreign(Language.Java)]
		public int GetOffsetX()
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			return shadowDrawable.getOffsetX();
		@}

		[Foreign(Language.Java)]
		public void SetOffsetY(int offsetY)
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			shadowDrawable.setOffsetY(offsetY);
		@}

		[Foreign(Language.Java)]
		public int GetOffsetY()
		@{
			com.fuse.android.graphics.ShadowDrawable shadowDrawable = (com.fuse.android.graphics.ShadowDrawable)@{ShadowImpl:of(_this).shadowDrawable:get()};
			return shadowDrawable.getOffsetY();
		@}
	}
}
