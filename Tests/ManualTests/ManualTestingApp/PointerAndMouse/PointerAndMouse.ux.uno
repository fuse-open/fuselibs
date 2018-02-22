using Uno;
using Fuse;
using Fuse.Input;
using Fuse.Controls;

public partial class PointerAndMouse 
{
    private Random _random;

    public PointerAndMouse()
    {
        InitializeUX();
        this.Title = "Pointer & Mouse";
        _random = new Random(1337);
    }

    float4 RandomColor()
    {
        return float4(
            (float)_random.NextDouble(),
            (float)_random.NextDouble(),
            (float)_random.NextDouble(),
            (float)_random.NextDouble());
    }

    void Button1_Click(object sender, PointerEventArgs args)
    {
        if (args.IsPrimary)
        {
            Button1Color.Color = RandomColor();
        }
    }

    void Button2_Click(object sender, PointerEventArgs args)
    {
        if (!args.IsPrimary)
        {
            Button2Color.Color = RandomColor();
        }
    }

    void Button3_WheelChanged(object sender, PointerWheelMovedArgs args)
    {
        if (!args.IsHandled)
        {
            var colorDelta = args.WheelDelta.Y * 0.006f;
            var color = Button3Color.Color;
            Button3Color.Color = float4(IncreaseValue(color.X, colorDelta),
                                        IncreaseValue(color.Y, colorDelta),
                                        IncreaseValue(color.Z, colorDelta), color.W);
        }
    }

    float IncreaseValue(float sourceValue, float delta)
    {
        var result = sourceValue + delta;
        if (result > 1)
            return 1;
        if (result < 0)
            return 0;
        return result;
    }
}
