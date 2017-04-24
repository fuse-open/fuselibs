The `Text` UI-control renders read-only text.

You can import a @Font from ttf files containing TrueType fonts. Because a font is typically referred to throughout an application, it is best to simply create a global resource for it using `ux:Global`. This way of importing the font ensures that the font is available throughout the whole project, and is only loaded once.

> **Note**
>
> When running desktop preview, neither fallback fonts, colored glyphs, nor Unicode characters outside the basic multilingual plane are supported.
>
> Because of this, **certain text features (e.g. emoji) are not supported when running local preview.**
> Do not be surprised if desktop rendering doesn't match device rendering 100%. This is an issue that is being worked on.