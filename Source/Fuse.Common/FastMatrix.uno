using Uno;

namespace Fuse
{
	public sealed class FastMatrix
	{
		float4x4 _matrix;
		public float4x4 Matrix { get { return _matrix; } }

		internal float3 Translation { get { return _matrix.M41M42M43; } }

		bool _hasNonTranslation;
		public bool HasNonTranslation { get { return _hasNonTranslation; } }
		
		bool _isValid = true;
		/**
			 A FastMatrix may be invalid if it's the result of an operation that could not be done,
			 such as a failed inversion. If the matrix is not valid then the `Matrix` values are undefined.
		*/
		public bool IsValid { get { return _isValid; } }

		public bool IsIdentity
		{
			get
			{
				if (!_hasNonTranslation)
					return _matrix.M41M42M43 == float3(0);
				else
				{
					return _matrix == float4x4.Identity;
				}
			}
		}

		FastMatrix()
		{
			_matrix = float4x4.Identity;
		}

		FastMatrix(FastMatrix orig)
		{
			_matrix = orig._matrix;
			_hasNonTranslation = orig._hasNonTranslation;
			_isValid = orig._isValid;
		}

		public static FastMatrix Identity() { return new FastMatrix(); }

		public FastMatrix Copy()
		{
			return new FastMatrix(this);
		}

		public void ResetIdentity()
		{
			_matrix = float4x4.Identity;
			_hasNonTranslation = false;
			_isValid = true;
		}
		
		public static FastMatrix FromFloat4x4(float4x4 m)
		{
			var k = new FastMatrix();
			k._matrix = m;
			k._hasNonTranslation = true; // TODO: optimize
			return k;
		}

		public void AppendTranslation(float x, float y, float z)
		{
			if (!_hasNonTranslation)
			{
				SimpleTranslation(x, y, z);
			}
			else
			{
				_matrix = Uno.Matrix.Mul(_matrix, Uno.Matrix.Translation(float3(x, y, z)));
			}
		}

		public void PrependTranslation(float x, float y, float z)
		{
			if (!_hasNonTranslation)
			{
				SimpleTranslation(x, y, z);
			}
			else
			{
				_matrix = Uno.Matrix.Mul(Uno.Matrix.Translation(float3(x, y, z)), _matrix);
			}
		}

		public void AppendRotation(float zRadians)
		{
			_matrix = Uno.Matrix.Mul(_matrix, Uno.Matrix.RotationZ(zRadians));
			_hasNonTranslation = true;
		}

		public void PrependRotation(float zRadians)
		{
			_matrix = Uno.Matrix.Mul(Uno.Matrix.RotationZ(zRadians), _matrix);
			_hasNonTranslation = true;
		}

		public void AppendScale(float factor)
		{
			_matrix = Uno.Matrix.Mul(_matrix, Uno.Matrix.Scaling(float3(factor, factor, factor)));
			_hasNonTranslation = true;
		}

		public void PrependScale(float factor)
		{
			_matrix = Uno.Matrix.Mul(Uno.Matrix.Scaling(float3(factor, factor, factor)), _matrix);
			_hasNonTranslation = true;
		}
		
		public void PrependShear(float xRadians, float yRadians)
		{
			_matrix = Uno.Matrix.Mul(Uno.Matrix.Shear(float2(xRadians,yRadians)), _matrix);
			_hasNonTranslation = true;
		}

		public void AppendShear(float xRadians, float yRadians)
		{
			_matrix = Uno.Matrix.Mul(_matrix, Uno.Matrix.Shear(float2(xRadians,yRadians)) );
			_hasNonTranslation = true;
		}
		
		void SimpleTranslation(float x, float y, float z)
		{
			_matrix.M41 += x;
			_matrix.M42 += y;
			_matrix.M43 += z;
		}

		public FastMatrix Mul(FastMatrix m)
		{
			// TODO: optimize

			var res = new FastMatrix();
			res._matrix = Uno.Matrix.Mul(_matrix, m._matrix);
			res._hasNonTranslation = _hasNonTranslation || m._hasNonTranslation;
			res._isValid = _isValid && m._isValid;

			return res;
		}

		public void Invert()
		{
			if (!_hasNonTranslation)
			{
				_matrix.M41 = -_matrix.M41;
				_matrix.M42 = -_matrix.M42;
				_matrix.M43 = -_matrix.M43;
			}
			else
			{
				float4x4 result = float4x4.Identity;
				_isValid = _isValid && Uno.Matrix.TryInvert(_matrix, out result);
				_matrix = result;
			}
		}

		public void AppendScale(float3 scale)
		{
			_matrix = Uno.Matrix.Mul(_matrix, Uno.Matrix.Scaling(scale));
			_hasNonTranslation = true;
		}

		public void AppendRotationQuaternion(float4 q)
		{
			_matrix = Uno.Matrix.Mul(_matrix, Uno.Matrix.RotationQuaternion(q));
			_hasNonTranslation = true;
		}

		public void AppendTranslation(float3 offset)
		{
			_matrix = Uno.Matrix.Mul(_matrix, Uno.Matrix.Translation(offset));
		}

		public void PrependScale(float3 scale)
		{
			_matrix = Uno.Matrix.Mul(Uno.Matrix.Scaling(scale), _matrix);
			_hasNonTranslation = true;
		}

		public void PrependRotationQuaternion(float4 q)
		{
			_matrix = Uno.Matrix.Mul(Uno.Matrix.RotationQuaternion(q), _matrix);
			_hasNonTranslation = true;
		}

		public void PrependTranslation(float3 offset)
		{
			_matrix = Uno.Matrix.Mul(Uno.Matrix.Translation(offset), _matrix);
		}
		
		public void PrependFastMatrix(FastMatrix fm)
		{
			_isValid = _isValid && fm._isValid;
			if (_hasNonTranslation || fm._hasNonTranslation)
			{
				_matrix = Uno.Matrix.Mul(fm.Matrix, _matrix);
				_hasNonTranslation = true;
			}
			else
			{
				_matrix.M41 += fm._matrix.M41;
				_matrix.M42 += fm._matrix.M42;
				_matrix.M43 += fm._matrix.M43;
			}
		}
		
		public void AppendFastMatrix(FastMatrix fm)
		{
			_isValid = _isValid && fm._isValid;
			if (_hasNonTranslation || fm._hasNonTranslation)
			{
				_matrix = Uno.Matrix.Mul(_matrix, fm.Matrix);
				_hasNonTranslation = true;
			}
			else
			{
				_matrix.M41 += fm._matrix.M41;
				_matrix.M42 += fm._matrix.M42;
				_matrix.M43 += fm._matrix.M43;
			}
		}

		public float3 TransformVector(float3 v)
		{
			if (_hasNonTranslation)
			{
				return Vector.TransformCoordinate(v, Matrix);
			}
			else
			{
				return v + Translation;
			}
		}
	}
}