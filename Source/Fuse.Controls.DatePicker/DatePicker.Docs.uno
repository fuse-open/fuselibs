namespace Fuse.Controls
{
	/**
		Displays a component to select a date.

		Currently, the DatePicker only has native implementations, so it should be contained in a @NativeViewHost.

		A `DatePicker` can be used to select a specific date value. The type of its `Value`, `MinValue`, and `MaxValue`
		properties are each of type `Uno.DateTime`, which is marshalled automatically to and from the JavaScript `Date` type.
		This makes interaction between JavaScript and the `DatePicker` type seamless via databinding. If you plan to wrap
		a `DatePicker` in a UX component and use a UX property to hook up to any of these values, the `Uno.DateTime` type
		should be used.

		Both `Uno.DateTime` and JS' `Date` type represent a specific timestamp. These types have both date and time
		components, and their interpretation depends on a given time zone, which can cause a great deal of confusion. To
		simplify all of this and ensure consistent behavior accross different time zones and locales, `DatePicker` will assume
		incoming values are relative to UTC, and truncate the time component to midnight, effectively ignoring the time
		component altogether. Similarly, values read from `DatePicker` properties will only consist of a date component at
		midnight UTC. This makes values going to/from the `DatePicker` control easy to create and interpret consistently, but
		also means that if a value with a time component other than midnight at UTC is written to one of `DatePicker`'s `Value`
		properties, subsequent values read from the property may not match the written value, as the time component will have
		been truncated.

		Note that this control should not be used to deal with historic dates, as calendar/date and timestamp translation is
		inconsistent between different locales due to when and where different calendar systems were adopted. However, the
		behavior is consistent for all dates since at least 1900 including all representable future dates.

		## Example

		The following example shows how to set up a `DatePicker` object with a specific minimum and maximum value, and set the
		value from JS using a `Date` object:

			<StackPanel>
				<JavaScript>
					var Observable = require("FuseJS/Observable");

					var someDate = Observable(new Date(Date.parse("2007-02-14T00:00:00.000Z")));

					someDate.onValueChanged(module, function(date) {
						console.log("someDate changed: " + JSON.stringify(date));
					});

					module.exports = {
						someDate: someDate,

						minDate: new Date(Date.parse("1950-01-01T00:00:00.000Z")),
						maxDate: new Date(Date.parse("2050-01-01T00:00:00.000Z")),

						whoYouGonnaCall: function() {
							someDate.value = new Date(Date.parse("1984-06-08T00:00:00.000Z"));
						}
					};
				</JavaScript>

				<NativeViewHost>
					<DatePicker Value="{someDate}" MinValue="{minDate}" MaxValue="{maxDate}" />
				</NativeViewHost>

				<Button Text="Who you gonna call?" Clicked="{whoYouGonnaCall}" Margin="5" />
			</StackPanel>

	*/
	public partial class DatePicker
	{
	}
}