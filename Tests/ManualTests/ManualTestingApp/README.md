# Manual Test App

This test app is meant to cover things that can' t be tested from unit tests, either because they require high-level interaction or need a human eye to see if something is wrong.

The project is split into two parts. All things that need Uno code go into the `UnoComponents.unoproj`, and the rest into the main `ManualTestingApp.unoproj`. This is how a normal app would be structured in Fuse if it used Uno. The preview then works normally on the top-level app.
