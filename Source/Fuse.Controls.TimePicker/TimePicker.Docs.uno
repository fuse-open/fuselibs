namespace Fuse.Controls
{
	/**
		Displays a component to select a time.

		Currently, the TimePicker only has native implementations, so it should be contained in a @NativeViewHost.

		A `TimePicker` can be used to select a specific time value. The type of its `Value` property is `Uno.DateTime`,
		which is marshalled automatically to and from the JavaScript `Date` type. This makes interaction between JavaScript
		and the `TimePicker` type seamless via databinding. If you plan to wrap a `TimePicker` in a UX component and use a
		UX property to hook up this value, the `Uno.DateTime` type should be used.

		Both `Uno.DateTime` and JS' `Date` type represent a specific timestamp. These types have both date and time
		components, and their interpretation depends on a given time zone, which can cause a great deal of confusion. To
		simplify all of this and ensure consistent behavior accross different time zones and locales, `TimePicker` will assume
		incoming values are relative to UTC, and truncate the date component to the Unix epoch (1 Jan 1970), effectively
		ignoring the date component altogether. Similarly, values read from `TimePicker` properties will only consist of a time
		component at on 1 Jan 1970. This makes values going to/from the `TimePicker` control easy to create and interpret
		consistently, but also means that if a value with a date component other than the unix epoch is written to TimePicker`'s
		`Value` property, subsequent values read from the property may not match the written value, as the date component will
		have been truncated.

		You should avoid modifying the `TimePicker` values programmatically while the control has focus, as this is known to
		have some issues on some Android devices (particularly ones which use the new `clock` appearance prior to Android 7).

		## Example

		The following example shows how to set up a `TimePicker` object and set the value from JS using a `Date` object:

			<StackPanel>
				<JavaScript>
					var Observable = require("FuseJS/Observable");

					var someTime = Observable(new Date(Date.parse("2007-02-14T12:34:56.000Z")));

					someTime.onValueChanged(module, function(date) {
						console.log("someTime changed: " + JSON.stringify(date));
					});

					module.exports = {
						someTime: someTime,

						timeToGetCracking: function() {
							someTime.value = new Date(Date.parse("1970-01-01T13:37:00.000Z"));
						}
					};
				</JavaScript>

				<NativeViewHost>
					<TimePicker Value="{someTime}" Is24HourView="true" />
				</NativeViewHost>

				<Button Text="Time to get cracking!" Clicked="{timeToGetCracking}" Margin="5" />
			</StackPanel>

	*/
	public partial class TimePicker
	{
	}
}
