#include <hb-ft-cached.h>
#include <harfbuzz/hb-ft.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_ADVANCES_H

struct font_cache_t
{
	FT_Face ft_face;
	int load_flags;
	struct
	{
		bool loaded;
		hb_position_t v_origin_x;
		hb_position_t v_origin_y;
		hb_position_t h_advance;
		hb_position_t v_advance;
		hb_glyph_extents_t extents;
	} cache[];
};

// ----------------------------------------------------------------------------
// Caching functionality
static void
hb_ft_get_glyph_v_origin(
	int x_scale, int y_scale,
	FT_Face ft_face,
	hb_position_t *x,
	hb_position_t *y)
{
	/* Note: FreeType's vertical metrics grows downward while other FreeType coordinates
	 * have a Y growing upward.  Hence the extra negation. */
	*x = (hb_position_t)(ft_face->glyph->metrics.horiBearingX -   ft_face->glyph->metrics.vertBearingX);
	*y = (hb_position_t)(ft_face->glyph->metrics.horiBearingY - (-ft_face->glyph->metrics.vertBearingY));

	if (x_scale < 0)
		*x = -*x;
	if (y_scale < 0)
		*y = -*y;
}

static void
hb_ft_get_glyph_extents(
	int x_scale, int y_scale,
	FT_Face ft_face,
	hb_glyph_extents_t *extents)
{
	extents->x_bearing = (hb_position_t)ft_face->glyph->metrics.horiBearingX;
	extents->y_bearing = (hb_position_t)ft_face->glyph->metrics.horiBearingY;
	extents->width = (hb_position_t)ft_face->glyph->metrics.width;
	extents->height = (hb_position_t)-ft_face->glyph->metrics.height;

	if (x_scale < 0)
	{
		extents->x_bearing = -extents->x_bearing;
		extents->width = -extents->width;
	}
	if (y_scale < 0)
	{
		extents->y_bearing = -extents->y_bearing;
		extents->height = -extents->height;
	}
}

static hb_position_t
hb_ft_get_glyph_h_advance(
	int x_scale,
	FT_Face ft_face,
	int load_flags,
	hb_codepoint_t glyph)
{
	FT_Fixed v;

	if (FT_Get_Advance(ft_face, glyph, load_flags, &v))
		return 0;

	// HACK, see: https://github.com/behdad/harfbuzz/issues/252
	if (v == 0 && glyph != 0 && ft_face->glyph->format != FT_GLYPH_FORMAT_OUTLINE)
		return x_scale < 0
			? (hb_position_t)-ft_face->glyph->metrics.horiAdvance
			: (hb_position_t)ft_face->glyph->metrics.horiAdvance; // Should already be in 16.16 units

	if (x_scale < 0)
		v = -v;

	return (hb_position_t)((v + (1<<9)) >> 10);
}

static hb_position_t
hb_ft_get_glyph_v_advance(
	int y_scale,
	FT_Face ft_face,
	int load_flags,
	hb_codepoint_t glyph)
{
	FT_Fixed v;

	if (FT_Get_Advance(ft_face, glyph, load_flags | FT_LOAD_VERTICAL_LAYOUT, &v))
		return 0;

	// HACK, see: https://github.com/behdad/harfbuzz/issues/252
	if (v == 0 && glyph != 0 && ft_face->glyph->format != FT_GLYPH_FORMAT_OUTLINE)
		return y_scale < 0
			? (hb_position_t)ft_face->glyph->metrics.vertAdvance
			: (hb_position_t)-ft_face->glyph->metrics.vertAdvance; // Should already be in 16.16 units

	if (y_scale < 0)
		v = -v;

	/* Note: FreeType's vertical metrics grows downward while other FreeType coordinates
	 * have a Y growing upward.  Hence the extra negation. */
	return (hb_position_t)((-v + (1<<9)) >> 10);
}

static void
cache_glyph(
	hb_font_t* font,
	font_cache_t* cache,
	hb_codepoint_t glyph)
{
	auto glyph_cache = &cache->cache[glyph];
	if (glyph_cache->loaded)
		return;
	glyph_cache->loaded = true;
	int x_scale, y_scale;
	hb_font_get_scale(font, &x_scale, &y_scale);
	if (FT_Load_Glyph(cache->ft_face, glyph, cache->load_flags))
		return;

	hb_ft_get_glyph_v_origin(
		x_scale, y_scale,
		cache->ft_face,
		&glyph_cache->v_origin_x,
		&glyph_cache->v_origin_y);

	hb_ft_get_glyph_extents(
		x_scale, y_scale,
		cache->ft_face,
		&glyph_cache->extents);

	glyph_cache->h_advance = hb_ft_get_glyph_h_advance(
		x_scale,
		cache->ft_face,
		cache->load_flags,
		glyph);

	glyph_cache->v_advance = hb_ft_get_glyph_v_advance(
		y_scale,
		cache->ft_face,
		cache->load_flags,
		glyph);
}

// ----------------------------------------------------------------------------
// Cached funcs
static hb_bool_t
cached_get_font_h_extents(
	hb_font_t *font,
	void *font_data,
	hb_font_extents_t *metrics,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	FT_Face ft_face = cache->ft_face;
	metrics->ascender = (hb_position_t)ft_face->size->metrics.ascender;
	metrics->descender = (hb_position_t)ft_face->size->metrics.descender;
	metrics->line_gap = (hb_position_t)(ft_face->size->metrics.height - (ft_face->size->metrics.ascender - ft_face->size->metrics.descender));

	int x_scale, y_scale;
	hb_font_get_scale(font, &x_scale, &y_scale);

	if (y_scale < 0)
	{
		metrics->ascender = -metrics->ascender;
		metrics->descender = -metrics->descender;
		metrics->line_gap = -metrics->line_gap;
	}
	return true;
}

static hb_bool_t
cached_get_nominal_glyph(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t unicode,
	hb_codepoint_t *glyph,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	FT_Face ft_face = cache->ft_face;
	unsigned int g = FT_Get_Char_Index(ft_face, unicode);

	if (!g)
		return false;

	*glyph = g;
	return true;
}

static hb_bool_t
cached_get_variation_glyph(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t unicode,
	hb_codepoint_t variation_selector,
	hb_codepoint_t *glyph,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	FT_Face ft_face = cache->ft_face;
	unsigned int g = FT_Face_GetCharVariantIndex(ft_face, unicode, variation_selector);

	if (!g)
		return false;

	*glyph = g;
	return true;
}

static hb_position_t
cached_get_glyph_h_advance(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t glyph,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	cache_glyph(font, cache, glyph);
	return cache->cache[glyph].h_advance;
}

static hb_position_t
cached_get_glyph_v_advance(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t glyph,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	cache_glyph(font, cache, glyph);
	return cache->cache[glyph].v_advance;
}

static hb_bool_t
cached_get_glyph_v_origin(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t glyph,
	hb_position_t *x,
	hb_position_t *y,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	cache_glyph(font, cache, glyph);
	*x = cache->cache[glyph].v_origin_x;
	*y = cache->cache[glyph].v_origin_y;
	return true;
}

static hb_position_t
cached_get_glyph_h_kerning(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t left_glyph,
	hb_codepoint_t right_glyph,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	FT_Face ft_face = cache->ft_face;
	FT_Vector kerningv;

	unsigned int x_ppem, y_ppem;
	hb_font_get_ppem(font, &x_ppem, &y_ppem);
	FT_Kerning_Mode mode = x_ppem ? FT_KERNING_DEFAULT : FT_KERNING_UNFITTED;
	if (FT_Get_Kerning(ft_face, left_glyph, right_glyph, mode, &kerningv))
		return 0;

	return (hb_position_t)kerningv.x;
}

static hb_bool_t
cached_get_glyph_extents(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t glyph,
	hb_glyph_extents_t *extents,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	cache_glyph(font, cache, glyph);
	*extents = cache->cache[glyph].extents;
	return true;
}

static hb_bool_t
cached_get_glyph_contour_point(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t glyph,
	unsigned int point_index,
	hb_position_t *x,
	hb_position_t *y,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	FT_Face ft_face = cache->ft_face;
	int load_flags = cache->load_flags;

	if (FT_Load_Glyph(ft_face, glyph, load_flags))
		return false;

	if (ft_face->glyph->format != FT_GLYPH_FORMAT_OUTLINE)
		return false;

	if (point_index >= (unsigned int)ft_face->glyph->outline.n_points)
		return false;

	*x = (hb_position_t)ft_face->glyph->outline.points[point_index].x;
	*y = (hb_position_t)ft_face->glyph->outline.points[point_index].y;

	return true;
}

static hb_bool_t
cached_get_glyph_name(
	hb_font_t *font,
	void *font_data,
	hb_codepoint_t glyph,
	char *name, unsigned int size,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	FT_Face ft_face = cache->ft_face;

	hb_bool_t ret = !FT_Get_Glyph_Name(ft_face, glyph, name, size);
	if (ret && (size && !*name))
		ret = false;

	return ret;
}

static hb_bool_t
cached_get_glyph_from_name(
	hb_font_t *font,
	void *font_data,
	const char *name, int len, /* -1 means nul-terminated */
	hb_codepoint_t *glyph,
	void *user_data)
{
	font_cache_t* cache = (font_cache_t*)font_data;
	FT_Face ft_face = cache->ft_face;

	if (len < 0)
		*glyph = FT_Get_Name_Index(ft_face, (FT_String *)name);
	else {
		/* Make a nul-terminated version. */
		char buf[128];
		int buflen = (int)sizeof (buf) - 1;
		if (buflen < len)
			len = buflen;
		strncpy(buf, name, len);
		buf[len] = '\0';
		*glyph = FT_Get_Name_Index(ft_face, buf);
	}

	if (*glyph == 0)
	{
		/* Check whether the given name was actually the name of glyph 0. */
		char buf[128];
		if (!FT_Get_Glyph_Name(ft_face, 0, buf, sizeof (buf)) &&
				len < 0 ? !strcmp(buf, name) : !strncmp(buf, name, len))
			return true;
	}

	return *glyph != 0;
}

static font_cache_t* create_cache(FT_Face ft_face, int load_flags)
{
	font_cache_t* result = (font_cache_t*)calloc(sizeof *result + sizeof result->cache[0] * ft_face->num_glyphs, 1);
	result->ft_face = ft_face;
	result->load_flags = load_flags;
	return result;
}

static void delete_cache(void* cache)
{
	free(cache);
}

static hb_font_funcs_t* static_ft_cached_funcs = NULL;

void hb_ft_font_cached_set_funcs(hb_font_t* font)
{
	FT_Face ft_face = hb_ft_font_get_face(font);
	int load_flags = hb_ft_font_get_load_flags(font);

	if (!static_ft_cached_funcs)
	{
		hb_font_funcs_t* funcs = hb_font_funcs_create();

		hb_font_funcs_set_font_h_extents_func(funcs, cached_get_font_h_extents, NULL, NULL);
		//hb_font_funcs_set_font_v_extents_func (funcs, hb_ft_get_font_v_extents, NULL, NULL);
		hb_font_funcs_set_nominal_glyph_func(funcs, cached_get_nominal_glyph, NULL, NULL);
		hb_font_funcs_set_variation_glyph_func(funcs, cached_get_variation_glyph, NULL, NULL);
		hb_font_funcs_set_glyph_h_advance_func(funcs, cached_get_glyph_h_advance, NULL, NULL);
		hb_font_funcs_set_glyph_v_advance_func(funcs, cached_get_glyph_v_advance, NULL, NULL);
		//hb_font_funcs_set_glyph_h_origin_func (funcs, hb_ft_get_glyph_h_origin, NULL, NULL);
		hb_font_funcs_set_glyph_v_origin_func(funcs, cached_get_glyph_v_origin, NULL, NULL);
		hb_font_funcs_set_glyph_h_kerning_func(funcs, cached_get_glyph_h_kerning, NULL, NULL);
		//hb_font_funcs_set_glyph_v_kerning_func (funcs, hb_ft_get_glyph_v_kerning, NULL, NULL);
		hb_font_funcs_set_glyph_extents_func(funcs, cached_get_glyph_extents, NULL, NULL);
		hb_font_funcs_set_glyph_contour_point_func(funcs, cached_get_glyph_contour_point, NULL, NULL);
		hb_font_funcs_set_glyph_name_func(funcs, cached_get_glyph_name, NULL, NULL);
		hb_font_funcs_set_glyph_from_name_func(funcs, cached_get_glyph_from_name, NULL, NULL);

		hb_font_funcs_make_immutable(funcs);

		static_ft_cached_funcs = funcs;
	}

	hb_font_set_funcs(font, static_ft_cached_funcs, create_cache(ft_face, load_flags), delete_cache);
}
