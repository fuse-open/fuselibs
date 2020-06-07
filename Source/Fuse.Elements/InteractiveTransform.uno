using Uno;
using Uno.UX;

namespace Fuse.Elements
{
	public sealed class InteractiveTransform : Transform
	{
		float _zoomFactor = 1;
		[UXOriginSetter("SetZoomFactor")]
		public float ZoomFactor
		{
			get { return _zoomFactor; }
			set { SetZoomFactor(value, null); }
		}

		static Selector _zoomFactorName = "ZoomFactor";
		public void SetZoomFactor(float value, IPropertyListener origin)
		{
			if (_zoomFactor != value)
			{
				_zoomFactor = value;
				OnPropertyChanged(_zoomFactorName, origin);
				OnMatrixChanged();
			}
		}


		float _rotation = 0;
		[UXOriginSetter("SetRotation")]
		public float Rotation
		{
			get { return _rotation; }
			set { SetRotation(value, null); }
		}

		static Selector _rotationName = "Rotation";
		public void SetRotation(float value, IPropertyListener origin)
		{
			if (_rotation != value)
			{
				_rotation = value;
				OnPropertyChanged(_rotationName, origin);
				OnMatrixChanged();
			}
		}

		float2 _translation;
		[UXOriginSetter("SetTranslation")]
		public float2 Translation
		{
			get { return _translation; }
			set { SetTranslation(value, null); }
		}

		static Selector _translationName = "Translation";
		public void SetTranslation(float2 value, IPropertyListener origin)
		{
			if (_translation != value)
			{
				_translation = value;
				OnPropertyChanged(_translationName, origin);
				OnMatrixChanged();
			}
		}

		public override bool IsFlat { get { return true; } }

		public override void PrependTo(FastMatrix matrix)
		{
			matrix.PrependRotation(Rotation);
			matrix.PrependScale(ZoomFactor);
			matrix.PrependTranslation(Translation.X, Translation.Y,0);
		}

		public override void AppendTo(FastMatrix matrix, float weight = 1)
		{
			matrix.AppendTranslation(Translation.X, Translation.Y,0);
			matrix.AppendScale(ZoomFactor * weight);
			matrix.AppendRotation(Rotation * weight);
		}

		internal void AppendRotationScale(FastMatrix matrix)
		{
			matrix.AppendScale(ZoomFactor);
			matrix.AppendRotation(Rotation);
		}
	}
}