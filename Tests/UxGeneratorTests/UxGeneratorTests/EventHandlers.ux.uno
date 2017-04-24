using Uno;
using Fuse;
using Fuse.Elements;
using Fuse.Controls;

public partial class EventHandlers
{
    public bool WasClickProcessed { get; private set; }

 	public EventHandlers()
    {
        InitializeUX();
        WasClickProcessed = false;
    }

    void Test_Click(object sender, object args)
    {
        WasClickProcessed = true;
    }
}
