namespace Fuse.Controls
{
	/**
		PhotoPreview

		This element provides a fast path for previewing photos
		captured with `CameraView` inside a `NativeViewHost`.

		A `PhotoPreview` has to be connected to `CameraView`. Whenever
		a photo is captured it will be loaded by the connected `PhotoPreview`
		immediately. The `PhotoPreview` can also be connected to a
		`CameraView.PhotoLoaded` trigger which can be used to respond
		when the photo is ready.

		Example:

			<NativeViewHost>
				<Panel ux:Name="previewPanel" Visibility="Hidden">
					<Button Text="DISMISS" Alignment="Bottom" Margin="10">
						<Clicked>
							<Set previewPanel.Visibility="Hidden" />
							<Set cameraPanel.Visibility="Visible" />
						</Clicked>
					</Button>
					<PhotoPreview ux:Name="photoPreview" CameraView="cameraView" PreviewStretchMode="UniformToFill" />
				</Panel>
				<Panel ux:Name="cameraPanel">
					<CameraView ux:Name="cameraView" PreviewStretchMode="UniformToFill" ClipToBounds="true" />
				</Panel>
				<CameraView.PhotoLoaded PhotoPreview="photoPreview">
					<Set previewPanel.Visibility="Visible" />
					<Set cameraPanel.Visibility="Hidden" />
				</CameraView.PhotoLoaded>
			</NativeViewHost>
	*/
	public partial class PhotoPreview
	{
	}
}
