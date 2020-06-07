using Uno.UX;
using Uno.Collections;

namespace Fuse.Elements
{
	using Effects;

	public abstract partial class Element
	{
		List<Effect> _effects;

		private IList<Effect> Effects
		{
			get
			{
				if (_effects == null) _effects = new List<Effect>();
				return _effects;
			}
		}


		private bool HasEffects
		{
			get { return _effects != null && _effects.Count > 0; }
		}


		private bool HasActiveEffects
		{
			get
			{
				if (HasEffects)
				{
					foreach (var e in _effects)
					{
						if (e.Active)
							return true;
					}
				}

				return false;
			}
		}


		int _compositionEffects;

		private bool HasCompositionEffect
		{
			get { return _compositionEffects > 0; }
		}

		void OnEffectAdded(Effect e)
		{
			if (e.Type == EffectType.Composition)
				_compositionEffects++;

			Effects.Add(e);
			e.RenderingChanged += OnEffectRenderingChanged;
			e.RenderBoundsChanged += OnEffectRenderBoundsChanged;
			InvalidateVisual();
		}

		void OnEffectRemoved(Effect e)
		{
			if (e.Type == EffectType.Composition)
				_compositionEffects--;

			Effects.Remove(e);
			e.RenderingChanged -= OnEffectRenderingChanged;
			e.RenderBoundsChanged -= OnEffectRenderBoundsChanged;
			InvalidateVisual();
		}

		void OnEffectRenderingChanged(Effect e)
		{
			InvalidateVisual();
		}

		void OnEffectRenderBoundsChanged(Effect e)
		{
			InvalidateRenderBoundsWithEffects();
		}

		Cache _cache = null;
		Cache Cache
		{
			get { return _cache ?? (_cache = new Cache(this)); }
		}

		internal ElementBatchEntry ElementBatchEntry { get; set; }

		bool _warnOpacityFlat, _warnNoCacheDraw;
		void Composit(DrawContext dc)
		{
			if (Opacity <= 0.0f)
				return;

			var flat = AreChildrenFlat && IsLocalFlat;
			if (Opacity >= 1.0f)
			{
				if (flat)
					Cache.DrawHeuristically(dc);
				else
					CompositEffects(dc);
				return;
			}

			if (!HasActiveEffects && FastTrackDrawWithOpacity(dc))
			{
				return;
			}

			if (!flat && !_warnOpacityFlat)
			{
				_warnOpacityFlat = true;
				Fuse.Diagnostics.UserWarning( "This element has a partial opacity and is not flat."+
					" This will not render correctly. Put the opacity on a flat child panel instead.", this);
			}

			var r = Cache.DrawCached(dc);
			if (!r && !_warnNoCacheDraw)
			{
				_warnNoCacheDraw = true;
				Fuse.Diagnostics.InternalError( "This element can not be drawn.", this );
			}
		}

		protected virtual bool FastTrackDrawWithOpacity(DrawContext dc)
		{
			return false;
		}

		internal void CompositEffects(DrawContext dc)
		{
			bool hasActiveEffects = HasActiveEffects && Fuse.Internal.FuseConfig.EnableElementEffects;

			if (hasActiveEffects)
			{
				foreach (var e in _effects)
				{
					if (e.Type == EffectType.Underlay && e.Active)
					{
						extern double t;
						if defined(FUSELIBS_PROFILING)
						{
							t = Uno.Diagnostics.Clock.GetSeconds();
							Fuse.Profiling.BeginRegion(e.ToString());
						}

						e.Render(dc);

						if defined(FUSELIBS_PROFILING)
							Fuse.Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);
					}
				}
			}

			if (hasActiveEffects && HasCompositionEffect)
			{
				foreach (var e in _effects)
				{
					if (e.Type == EffectType.Composition && e.Active)
					{
						extern double t;
						if defined(FUSELIBS_PROFILING)
						{
							t = Uno.Diagnostics.Clock.GetSeconds();
							Fuse.Profiling.BeginRegion(e.ToString());
						}

						e.Render(dc);

						if defined(FUSELIBS_PROFILING)
							Fuse.Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);
					}
				}
			}
			else
			{
				DrawWithChildren(dc);
			}

			if (hasActiveEffects)
			{
				foreach (var e in _effects)
				{
					if (e.Type == EffectType.Overlay && e.Active)
					{
						extern double t;
						if defined(FUSELIBS_PROFILING)
						{
							t = Uno.Diagnostics.Clock.GetSeconds();
							Fuse.Profiling.BeginRegion(e.ToString());
						}

						e.Render(dc);

						if defined(FUSELIBS_PROFILING)
							Fuse.Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);
					}
				}
			}
		}
	}
}
