using Uno;
using Fuse;
using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Animations;

public partial class MoveAndScale 
{
    public MoveAndScale()
    {
        InitializeUX();
        this.Title = "Move & Scale";
    }

    bool forward;
    void MoveButton(object a, object s)
    {
        forward = !forward;
        UpdateBoxText();
        ButtonTrigger.Value = forward;
    }

    void UpdateBoxText()
    {
        b1.Text = !forward ? "Tap to move" : "Tap again to return";
    }
}

