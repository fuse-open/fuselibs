The following example will display a @Rectangle masked with an image from a file.

	<Rectangle Width="200" Height="88" Color="#EA5455">
	    <Mask Mode="Alpha" File="fuse.png" />
	</Rectangle>

The following example illustrates how you can supply your own @ImageSource.

	<Rectangle Width="200" Height="88">
	    <Mask Mode="Alpha">
	        <MultiDensityImageSource>
	            <FileImageSource Density="1" File="fuse@1x.png" />
	            <FileImageSource Density="2" File="fuse@2x.png" />
	            <FileImageSource Density="3" File="fuse@3x.png" />
	        </MultiDensityImageSource>
	    </Mask>

	    <LinearGradient AngleDegrees="60">
	        <GradientStop Color="#900C3F" Offset="0" />
	        <GradientStop Color="#2794EB" Offset="1" />
	    </LinearGradient>
	</Rectangle>