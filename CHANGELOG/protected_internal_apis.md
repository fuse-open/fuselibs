## Internal APIs
- The following `protected internal` members have been made just `internal`, as they refer to `internal` types and weren't meant to be available to derived types:
    * `Fuse.Controls.TextInputControl.Editor`
    * `Fuse.Controls.TextInputControl.TextInputControl(TextEdit)`
    * `Fuse.Physics.ForceFieldTrigger.SetForce(Body, float)`
    * `Fuse.Physics.ForceFieldEventTrigger.OnTriggered(Body)`
    * `Fuse.Controls.TextControl._textRenderer`
