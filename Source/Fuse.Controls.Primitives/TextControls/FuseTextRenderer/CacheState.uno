using Fuse.Text.Bidirectional;
using Fuse.Text;
using Uno.Collections;
using Uno;

namespace Fuse.Controls.FuseTextRenderer
{
	struct TextControlData
	{
		public readonly Fuse.Text.Font Font;
		public readonly string RenderValue;
		public readonly TextWrapping TextWrapping;
		public readonly TextTruncation TextTruncation;
		public readonly TextAlignment TextAlignment;
		public readonly float LineSpacing;
		public readonly float PixelWidth;

		public TextControlData(Fuse.Text.Font font, Fuse.Controls.TextControl control, float pixelWidth)
		{
			Font = font;
			RenderValue = control.RenderValue;
			TextWrapping = control.TextWrapping;
			TextTruncation = control.TextTruncation;
			TextAlignment = control.TextAlignment;
			LineSpacing = control.LineSpacing * control.Viewport.PixelsPerPoint;
			PixelWidth = pixelWidth;
		}

		public bool Subsumes(TextControlData other, Tolerances tolerances, bool measureOnly)
		{
			var withinWrapTolerance = measureOnly || TextAlignment == TextAlignment.Left
				// Optimisation: For left-aligned text or when only measuring we can
				// reuse results if we're not going to wrap the text with the new
				// size since the shaped text will then be identical.
				? tolerances.MinWrap - Tolerances.Epsilon <= PixelWidth
					&& PixelWidth <= tolerances.MaxWrap + Tolerances.Epsilon
				// For other text alignments the text runs' positions change with
				// the width of the element so we can't use the wrap tolerances
				// like with left-aligned text.
				: Math.Abs(PixelWidth - other.PixelWidth) <= Tolerances.Epsilon;

			return Font == other.Font
				&& RenderValue == other.RenderValue
				&& TextWrapping == other.TextWrapping
				&& TextTruncation == other.TextTruncation
				&& TextAlignment == other.TextAlignment
				&& Math.Abs(LineSpacing - other.LineSpacing) <= Tolerances.Epsilon
				&& withinWrapTolerance
				&& tolerances.MinTruncation - Tolerances.Epsilon <= PixelWidth
				&& PixelWidth <= tolerances.MaxTruncation + Tolerances.Epsilon;
		}
	}

	struct Tolerances
	{
		public static readonly float Epsilon = 0.01f;

		public float MinWrap;
		public float MaxWrap;
		public float MinTruncation;
		public float MaxTruncation;

		public Tolerances(int dummy)
		{
			MinWrap = 0;
			MaxWrap = float.PositiveInfinity;
			MinTruncation = 0;
			MaxTruncation = float.PositiveInfinity;
		}
	}

	static class Helpers
	{
		public static List<List<ShapedRun>> Wrap(TextControlData data, List<List<Run>> logicalRuns, out Tolerances tolerances)
		{
			tolerances = new Tolerances(0);
			var shapedRuns = Fuse.Text.Shape.ShapeLines(data.Font, logicalRuns);
			var wrappedLines = data.TextWrapping == TextWrapping.Wrap
				? Fuse.Text.Wrap.Lines(
					data.Font,
					shapedRuns,
					data.PixelWidth + Tolerances.Epsilon,
					out tolerances.MinWrap,
					out tolerances.MaxWrap)
				: shapedRuns;

			switch (data.TextTruncation)
			{
				case TextTruncation.None: return wrappedLines;
				case TextTruncation.Standard:
					var result = Truncate.Lines(
						data.Font,
						wrappedLines,
						data.PixelWidth + Tolerances.Epsilon,
						out tolerances.MinTruncation,
						out tolerances.MaxTruncation);
					return result;
					break;
				default: throw new Exception("TextTruncation not supported");
			}
		}

		public static float2 Measure(
			TextControlData data,
			List<List<ShapedRun>> wrappedRuns)
		{
			return Fuse.Text.Measure.Lines(data.Font, data.LineSpacing, wrappedRuns);
		}

		public static Renderer GetRenderer(
			TextControlData data,
			List<List<ShapedRun>> wrappedRuns,
			out List<List<PositionedRun>> positionedRuns)
		{
			var visualLines = Runs.GetVisual(wrappedRuns);
			positionedRuns = Fuse.Text.Shape.PositionLines(
				data.Font,
				data.PixelWidth,
				data.LineSpacing,
				Helpers.ToAlignmentNumber(data.TextAlignment),
				visualLines);
			return new Renderer(data.Font, positionedRuns, data.RenderValue.Length);
		}

		public static float ToAlignmentNumber(TextAlignment alignment)
		{
			switch (alignment)
			{
				case TextAlignment.Left: return 0.0f;
				case TextAlignment.Center: return 0.5f;
				case TextAlignment.Right: return 1.0f;
				default: throw new Exception("TextAlignment not supported");
			}
		}
	}

	abstract class CacheState : IDisposable
	{
		public abstract CacheState GetMeasurements(TextControlData data, out float2 measurements);
		public virtual bool TryGetMeasurements(TextControlData data, out float2 measurements)
		{
			measurements = float2();
			return false;
		}
		public CacheState GetBounds(TextControlData data, out Rect bounds)
		{
			float2 size;
			var result = GetMeasurements(data, out size);
			bounds = Fuse.Text.Measure.AlignedRectForSize(
				size,
				data.PixelWidth,
				Helpers.ToAlignmentNumber(data.TextAlignment));
			return result;
		}

		public abstract CacheState GetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns);
		public CacheState GetRenderer(TextControlData data, out Renderer renderer)
		{
			List<List<PositionedRun>> positionedRuns;
			return GetRenderer(data, out renderer, out positionedRuns);
		}
		public virtual bool TryGetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns)
		{
			renderer = null;
			positionedRuns = null;
			return false;
		}
		public bool TryGetRenderer(TextControlData data, out Renderer renderer)
		{
			List<List<PositionedRun>> positionedRuns;
			return TryGetRenderer(data, out renderer, out positionedRuns);
		}

		public virtual void Dispose() { }
	}

	class NothingCached : CacheState
	{
		public override CacheState GetMeasurements(TextControlData data, out float2 measurements)
		{
			if (data.RenderValue == null)
			{
				measurements = float2();
				return this;
			}

			return new LogicalRunsCached(data.RenderValue).GetMeasurements(data, out measurements);
		}

		public override CacheState GetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns)
		{
			if (data.RenderValue == null)
			{
				renderer = null;
				positionedRuns = new List<List<PositionedRun>>();
				return this;
			}

			return new LogicalRunsCached(data.RenderValue).GetRenderer(data, out renderer, out positionedRuns);
		}
	}

	class LogicalRunsCached : CacheState
	{
		string _renderValue;
		List<List<Run>> _logicalRuns;

		public LogicalRunsCached(string renderValue)
		{
			_renderValue = renderValue;
			_logicalRuns = Fuse.Text.Wrap.ActualLineBreaks(Runs.GetLogical(new Substring(renderValue)));
		}

		public override CacheState GetMeasurements(TextControlData data, out float2 measurements)
		{
			if (data.RenderValue != _renderValue)
				return new NothingCached().GetMeasurements(data, out measurements);

			Tolerances tolerances;
			var wrappedRuns = Helpers.Wrap(data, _logicalRuns, out tolerances);
			measurements = Helpers.Measure(data, wrappedRuns);
			return new MeasurementsCached(this, data, wrappedRuns, tolerances, measurements);
		}

		public override CacheState GetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns)
		{
			if (data.RenderValue != _renderValue)
				return new NothingCached().GetRenderer(data, out renderer, out positionedRuns);

			Tolerances tolerances;
			var wrappedRuns = Helpers.Wrap(data, _logicalRuns, out tolerances);
			renderer = Helpers.GetRenderer(data, wrappedRuns, out positionedRuns);
			return new RendererCached(this, data, wrappedRuns, tolerances, renderer, positionedRuns);
		}
	}

	class MeasurementsCached : CacheState
	{
		readonly LogicalRunsCached _previousState;
		readonly TextControlData _data;
		readonly List<List<ShapedRun>> _wrappedRuns;
		readonly Tolerances _tolerances;
		internal readonly float2 _measurements;

		public MeasurementsCached(LogicalRunsCached previousState, TextControlData data, List<List<ShapedRun>> wrappedRuns, Tolerances tolerances, float2 measurements)
		{
			_previousState = previousState;
			_data = data;
			_wrappedRuns = wrappedRuns;
			_tolerances = tolerances;
			_measurements = measurements;
		}

		public override CacheState GetMeasurements(TextControlData data, out float2 measurements)
		{
			if (TryGetMeasurements(data, out measurements))
			{
				return this;
			}
			else
			{
				return _previousState.GetMeasurements(data, out measurements);
			}
		}

		public override bool TryGetMeasurements(TextControlData data, out float2 measurements)
		{
			if (!data.Subsumes(_data, _tolerances, true))
			{
				measurements = float2();
				return false;
			}

			measurements = _measurements;
			return true;
		}

		public override CacheState GetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns)
		{
			if (!data.Subsumes(_data, _tolerances, false))
				return _previousState.GetRenderer(data, out renderer, out positionedRuns);

			renderer = Helpers.GetRenderer(data, _wrappedRuns, out positionedRuns);
			return new EverythingCached(
				_previousState,
				_data,
				_wrappedRuns,
				_tolerances,
				_measurements,
				renderer,
				positionedRuns);
		}
	}

	class RendererCached : CacheState
	{
		readonly LogicalRunsCached _previousState;
		readonly TextControlData _data;
		readonly List<List<ShapedRun>> _wrappedRuns;
		readonly Tolerances _tolerances;
		internal readonly Renderer _renderer;
		internal readonly List<List<PositionedRun>> _positionedRuns;

		public RendererCached(LogicalRunsCached previousState, TextControlData data, List<List<ShapedRun>> wrappedRuns, Tolerances tolerances, Renderer renderer, List<List<PositionedRun>> positionedRuns)
		{
			_previousState = previousState;
			_data = data;
			_wrappedRuns = wrappedRuns;
			_tolerances = tolerances;
			_renderer = renderer;
			_positionedRuns = positionedRuns;
		}

		public override CacheState GetMeasurements(TextControlData data, out float2 measurements)
		{
			if (!data.Subsumes(_data, _tolerances, true))
			{
				Dispose();
				return _previousState.GetMeasurements(data, out measurements);
			}

			measurements = Helpers.Measure(data, _wrappedRuns);
			return new EverythingCached(
				_previousState,
				_data,
				_wrappedRuns,
				_tolerances,
				measurements,
				_renderer,
				_positionedRuns);
		}

		public override CacheState GetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns)
		{
			if (TryGetRenderer(data, out renderer, out positionedRuns))
			{
				return this;
			}
			else
			{
				Dispose();
				return _previousState.GetRenderer(data, out renderer, out positionedRuns);
			}
		}

		public override bool TryGetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns)
		{
			if (!data.Subsumes(_data, _tolerances, false))
			{
				renderer = null;
				positionedRuns = null;
				return false;
			}

			renderer = _renderer;
			positionedRuns = _positionedRuns;

			return true;
		}


		public override void Dispose()
		{
			_renderer.Dispose();
		}
	}

	class EverythingCached : CacheState
	{
		readonly LogicalRunsCached _previousState;
		readonly TextControlData _data;
		readonly Tolerances _tolerances;
		internal readonly float2 _measurements;
		internal readonly Renderer _renderer;
		internal readonly List<List<PositionedRun>> _positionedRuns;

		public EverythingCached(
			LogicalRunsCached previousState,
			TextControlData data,
			List<List<ShapedRun>> wrappedRuns,
			Tolerances tolerances,
			float2 measurements,
			Renderer renderer,
			List<List<PositionedRun>> positionedRuns)
		{
			_previousState = previousState;
			_data = data;
			_tolerances = tolerances;
			_measurements = measurements;
			_renderer = renderer;
			_positionedRuns = positionedRuns;
		}

		public override CacheState GetMeasurements(TextControlData data, out float2 measurements)
		{
			if (TryGetMeasurements(data, out measurements))
			{
				return this;
			}
			else
			{
				Dispose();
				return _previousState.GetMeasurements(data, out measurements);
			}
		}

		public override bool TryGetMeasurements(TextControlData data, out float2 measurements)
		{
			if (!data.Subsumes(_data, _tolerances, true))
			{
				measurements = float2();
				return false;
			}

			measurements = _measurements;
			return true;
		}

		public override CacheState GetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns)
		{
			if (TryGetRenderer(data, out renderer, out positionedRuns))
			{
				return this;
			}
			else
			{
				Dispose();
				return _previousState.GetRenderer(data, out renderer, out positionedRuns);
			}
		}

		public override bool TryGetRenderer(TextControlData data, out Renderer renderer, out List<List<PositionedRun>> positionedRuns)
		{
			if (!data.Subsumes(_data, _tolerances, false))
			{
				renderer = null;
				positionedRuns = null;
				return false;
			}

			renderer = _renderer;
			positionedRuns = _positionedRuns;

			return true;
		}

		public override void Dispose()
		{
			_renderer.Dispose();
		}
	}
}
