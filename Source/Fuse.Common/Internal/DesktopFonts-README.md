# Steps to update the desktop fonts that we bundle with fuselibs

* First make sure that you've downloaded the existing DesktopFonts.stuff. Run (in this directory):

```
uno stuff install DesktopFonts.stuff
```

There should now be a subdirectory called `DesktopFonts` in this directory with
a bunch of .ttf files in it.

* Make the changes you want to make, e.g. add some fonts to the DesktopFonts directory.

* Pack and upload with stuff. Run (in this directory):

```
uno stuff pack DesktopFonts --name=DesktopFonts
uno stuff push --api-token=<YOUR_API_TOKEN> --url=<YOUR_URL> DesktopFonts/DesktopFonts.stuff-upload
echo "if \!Android && \!iOS {" > DesktopFonts.stuff
cat DesktopFonts/DesktopFonts.stuff >> DesktopFonts.stuff
echo "}" >> DesktopFonts.stuff
```
