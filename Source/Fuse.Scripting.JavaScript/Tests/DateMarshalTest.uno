using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Testing;

using Fuse;
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
			var dt = (DateTime)c.Wrap(args[0]);

			const long oneHourInDotNetTicks = 36000000000L;
			var newDt = new DateTime(dt.Ticks + oneHourInDotNetTicks, dt.Kind);

			return c.Unwrap(newDt);
		}
	}

	public class DateMarshalTestScriptClass : Node
	{
		static DateMarshalTestScriptClass()
		{
			ScriptClass.Register(typeof(DateMarshalTestScriptClass),
				new ScriptMethod<DateMarshalTestScriptClass>("setDateTime", SetDateTime));
		}

		public DateTime DateTime { get; set; }

		static void SetDateTime(DateMarshalTestScriptClass self, object[] args)
		{
			self.DateTime = (DateTime)args[0];
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
		public void JSRoundTripUnixEpochDateMatches()
		{
			var e = new UX.DateMarshal.UnixEpochDateRoundTrip();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				e.RoundTripComponent.CallReadDate.Perform();
				root.StepFrameJS();
			}
		}

		[Test]
		public void JSRoundTripUnixEpochDateTimeMatches()
		{
			var e = new UX.DateMarshal.UnixEpochDateRoundTrip();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				root.StepFrameJS();

				// Expected date/time (UTC): January 1 1970 00:00:00 (Unix Epoch)
				const long expectedTicks = 621355968000000000L;
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

		[Test]
		public void PassDateToScriptClassAsDateTime()
		{
			var e = new UX.DateMarshal.PassDateToScriptClass();
			using (var root = TestRootPanel.CreateWithChild(e))
			{
				e.CallTest.Perform();
				root.StepFrameJS();

				// Expected date/time (UTC): January 3 1337 03:07:13.371
				const long expectedTicks = 421602736333710000L;
				Assert.AreEqual(e.ScriptClassInstance.DateTime, new DateTime(expectedTicks, DateTimeKind.Utc));
			}
		}
	}
}
