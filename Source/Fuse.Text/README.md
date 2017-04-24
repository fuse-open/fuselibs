# Fuse.Text

Text rendering using Harfbuzz

## Making changes

In the Implementation directory we make use of Foreign CPlusPlus. This is code
that, with some care, can be used both on C++ backends and CIL backends.

*Important:* After having made changes to or added any Foreign CPlusPlus
methods, the PInvoke libraries need to be rebuilt for Windows (both X86 and
X64) and OSX. This can be done using `uno build pinvoke -crelease`. The stuff files
containing these libs then need to be recreated and reuploaded.

## What the text goes through to be rendered

The driver that passes the text through the transformations necessary for
rendering is `Fuse.Controls.FuseTextRenderer.CacheState`, which also keeps
track of when we need to redo work due to changes.

* The text is transformed to logical bidirectional runs
    (`Fuse.Text.Bidirectional.Runs`), which is means chunking the text into
    lists of `Run`s in the same direction. A run is a substring of the input string
    and a `Level`, which tells us the nesting-level within runs of different direction,
    as well as the direction of the text.

    As an example, if we get the input text `abcABCdef`, where the upper-case
    letters are in a right-to-left language, it will be transformed into the
    runs (`abc`, 0), (`ABC`, 1), and (`def`, 0).

* Next we do _shaping_, which means translating from text to
    a list of glyphs (the graphical representation of a text symbol in a given
    font) and their position. Shaped glyphs have a _cluster_ which tells us the
    index in the original input string that the glyph stems from.  There is not
    necessarily a one-to-one correspondence between glyphs and the characters
    in the input string. As an example, `fi` might be shaped as a one-glyph
    ligature. We can also have several glyphs that stem from the same
    character. As an example `Å` might be shaped as a circle-formed glyph on
    top of a glyph for `A`.

* If wrapping is enabled, we do line wrapping, i.e. adding line breaks when the
   text overflows its allocated width. This uses the shaped glyphs and their
   positions.  See `Fuse.Text.Wrap`.

* If truncation is enabled, we do that as well, which means chopping off the
   end of the string and adding `...` if it overflows its allocated width. See
   `Fuse.Text.Truncate`.

* Next, we measure the text to see how much space it occupies in the layout.
   See `Fuse.Text.Measure`.

* Next, we reorder bidirectional text into its _visual_ order. This is done after
   line wrapping since the reordering works per-line.
   See `Fuse.Text.Bidirectional.Runs.GetVisual`.

   An example of reordering is if we have left-to-right text embedded in
   right-to-left text. Assuming upper-case is RTL, the runs `CAR car BAR`
   will be transformed to `BAR car CAR` to match the natural RTL reading order.

* Next, we shape the lines, which means assigning a position to each `Run` on each line, yielding
    `PositionedRun`s. Basically the runs in each line are placed next to eachother while taking into
    account the text's alignment. See `Fuse.Text.Shape`.

* Lastly, we create a renderer. See `Fuse.Text.Renderer`. This uses a global
    `Fuse.Text.GlyphAtlas`, which consists of a stack of packed (`Fuse.Text.RectPacker`)
    texture atlases (`Fuse.Text.TextureAtlas`) containing all the rendered
    glyphs in the app. The renderer creates vertex buffer objects that make use
    of the glyphs in the texture atlases.

    The actual drawing of a piece of text will consist of one draw call per
    texture atlas that the glyphs in the text come from. Typically this will be
    one or two.

## Fonts

The `Fuse.Text.FontFace` and `Fuse.Text.Font` abstract classes are used by the
new text rendering system.

The implementations that do the main work are `FreeTypeFont{,Face}`,
`CoreTextFont{,Face}`, and `HarfbuzzFont`. `HarfbuzzFont` is used by both
`FreeTypeFont` and `CoreTextFont` to do shaping, while they take care of the
rendering themselves. `CoreTextFont` is iOS only, but the others can be used on
all our main targets.

On top of this, there are two more generic `Font{,Face}`s, namely
`Fuse.Text.FallingBackFont{,Face}` and `LazyFont{,Face}`. A `FallingBackFont`
has a list of other fonts, which it uses in order when shaping. It first shapes
the text with the first font, and if there are any undefined characters left
(i.e. characters that are not in the Font), it tries the font next in the list
for that substring.

When there are long lists of fonts in a `FallingBackFont` it can be unnecessary
work to load all the fonts in it unless they are actually needed. `LazyFont`
solves this by loading a font on demand when it's actually used.

See `FuseTextRenderer` for how the fonts are created.

Code to query system fonts is located in `../FuseCore/Internal/SystemFont.uno`.
