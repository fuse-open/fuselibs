# Coding Style

Please consider using an [EditorConfig](http://editorconfig.org/)-capable
text-editor. Plug-ins exist for most popular text-editors. This ensures
that our [configuration file](../.editorconfig) gets respected, which
reduces needless commit-noise.

Generally, try to follow the local code-style of the source-file you're
editing. It's much more disturbing to swtich between multiple code-styles
within a source-file, than between source-files.

These guidelines apply only to code written and maintaned as a part of
this project. Any code that gets imported from some upstream source
should keep the style from its upstream. This ensures it's as easy as
possible to apply patches from the upstream-source.

## General

We generally try to write ideomatic code for each language we use. In
addition, we have some additional guidelines for some languages (listed
below).

Do not commit commented-out code. Commented-out code is harder to
maintain, as it's not actively compiled, and usually turns out being
nothing more than noise. If something is really important to keep around,
consider keeping it on a private branch, or as code that still gets
compiled, but not executed. Do note that dead code can easily get removed
by someone else.

Avoid needless white-space changes. Unnecessary white-space changes makes
hard to back-port patches, and increase the chance of merge-conflicts.
Please avoid them. They also make it harder to review a pull-request. If
a file is white-space broken, consider putting the white-space cleanup in
a separate commit, so it's easier to omit it when reviewing.

## Uno / C&#35;

We generally use [ideomatic C# code-style](https://msdn.microsoft.com/en-us/library/ff926074.aspx),
but we also have a few additional guidelines:

* Use tabs for indentation
* Non-public members are prefixed with an underscore, like so:
   ```Uno
   class Foo
   {
   	int _bar;
   }
   ```
* *Do not* use egyptian braces
* Use spaces around operators and keywords, but not inside parentheses and
  not around function calls. So, like this:
  ```Uno
  if (condition)
        foo(bar + 1);
  ```
  ...and not like this:
  ```Uno
  if( condition )
        foo( bar+1 );
  ```

## JavaScript

We generally try to write ideomatic JavaScript, but we also have a few
additional guidelines:

* Use tabs for indentation
* *Do* use egyptian braces
