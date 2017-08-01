using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse.Controls;
using Fuse.Navigation;
using Fuse.Scripting;
using FuseTest;

namespace Fuse.Reactive.Test
{
	public class DotNetDateTimeComponent : Panel
	{
		public DateTime TheDateTime { get; set; }
	}

	public class DateMarshalTestAddAnHourModule : NativeModule
	{
		public DateMarshalTestAddAnHourModule()
		{
			AddMember(new NativeFunction("AddAnHour", (NativeCallback)AddAnHour));
		}

		static object AddAnHour(Context c, object[] args)
		{
			DateTime dt;
			DateHelpers.TryConvertJSDateToDateTime(args[0], c, out dt);

			const long oneHourInDotNetTicks = 36000000000L;
			var newDt = new DateTime(dt.Ticks + oneHourInDotNetTicks, dt.Kind);

			return DateHelpers.ConvertDateTimeToJSDate(newDt, c);
		}
	}

	public class DateMarshalTest : TestBase
	{
		[Test]
		public void JSRoundTripDateMatches()
		{
			var e = new UX.DateMarshal.DateRoundTrip();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				e.RoundTripComponent.CallReadDate.Perform();
				root.StepFrameJS();

				// Expected date/time (UTC): November 1 1997 10:15:00
				const long expectedTicks = 630139761000000000L;
				var expectedDateTime = new DateTime(expectedTicks, DateTimeKind.Utc);

				Assert.AreEqual(e.DateTimeComponent.TheDateTime, expectedDateTime);
			}
		}

		[Test]
		public void JSRoundTripDateTimeMatches()
		{
			var e = new UX.DateMarshal.DateRoundTrip();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				// Expected date/time (UTC): November 1 1997 10:15:00
				const long expectedTicks = 630139761000000000L;
				var expectedDateTime = new DateTime(expectedTicks, DateTimeKind.Utc);

				Assert.AreEqual(e.DateTimeComponent.TheDateTime, expectedDateTime);
			}
		}

		[Test]
		public void NativeModuleDateRoundTripAddsAnHour()
		{
			var e = new UX.DateMarshal.NativeModuleDateRoundTrip();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				e.CallTest.Perform();
				root.StepFrameJS();
			}
		}
	}
}
