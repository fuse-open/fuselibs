using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Testing;
using Fuse;
using Fuse.Animations;
using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Navigation;
using Fuse.Reactive;
using Fuse.Triggers;

public class UxTests
{
    [Test]
    public void Children()
    {
        var panel = new Children();

        Assert.AreEqual(3, panel.Children.Count);
        Assert.IsTrue(panel.firstChild != null);
        Assert.AreEqual(1, panel.firstChild.Children.Count);
    }

    [Test]
    public void Attributes()
    {
        var panel = new Attributes();

        Assert.AreEqual(28, panel.FontSize);
        Assert.AreEqualSize(150, panel.Height);
        Assert.AreEqualSize(250, panel.Width);
        Assert.AreEqual(Visibility.Collapsed, panel.Visibility);
        Assert.AreEqual(float4 (2, 3, 4, 5), panel.Margin);
        Assert.IsFalse(panel.IsEnabled);
    }

    [Test]
    public void AppearanceAndFills()
    {
        var panel = new AppearanceAndFills();
        var rectangle = panel.FirstChild<Visual>() as Fuse.Controls.Rectangle;

        Assert.IsTrue(rectangle != null);
        Assert.AreEqual(1, rectangle.Fills.Count);

        var solidColor = rectangle.Fills[0] as SolidColor;
        Assert.IsTrue(solidColor != null);
        Assert.AreEqual(float4 (0.6f, 1f, 1f, 1f), solidColor.Color);
    }

    [Test]
    public void EventHandler()
    {
        var ctrl = new EventHandlers();

        Assert.IsFalse(ctrl.WasClickProcessed);
        ctrl.EmulateClick();
        Assert.IsTrue(ctrl.WasClickProcessed);
    }

    [Test]
    public void TriggerAndAnimator()
    {
        var panel = new TriggerAndAnimators();

        Assert.AreEqual(2, panel.Children.Count);
        var whileDisabled = panel.Children[0] as WhileDisabled;
        var exitingAnimation = panel.Children[1] as ExitingAnimation;
        Assert.IsTrue(whileDisabled != null);
        Assert.IsTrue(exitingAnimation != null);

        Assert.AreEqual(1, whileDisabled.Animators.Count);
        var change1 = whileDisabled.Animators[0] as Change<Size>;
        Assert.IsTrue(change1 != null);

        Assert.AreEqual(1, exitingAnimation.Animators.Count);
        var change2 = exitingAnimation.Animators[0] as Change<Size>;
        Assert.IsTrue(change2 != null);
    }


    [Test]
    public void TextFont()
    {
        var panel = new TextFont();
        var lastChild = panel.Children.Last() as FaBeer;
        Assert.IsTrue(lastChild != null);
        Assert.IsTrue(lastChild.Font != null);
    }

    [Test]
    public void JavaScript()
    {
        var panel = new Javascript();
        Assert.AreEqual(3, panel.Children.Count);

        var javascript = panel.Children[0] as JavaScript;
        var clickControl = panel.Children[1] as ClickControl;
        var stackPanel = panel.Children[2] as StackPanel;

        Assert.IsTrue(javascript != null);
        Assert.IsTrue(stackPanel != null);
        Assert.IsTrue(clickControl != null);

        Assert.AreEqual(1, clickControl.Bindings.Count);
        var eventBinding = clickControl.Bindings[0] as EventBinding;
        Assert.IsTrue(eventBinding != null);

        Assert.AreEqual(1, stackPanel.Children.Count);
        var each = stackPanel.Children[0] as Each;
        Assert.AreEqual(1, each.Bindings.Count);
        var dataBinding = each.Bindings[0] as DataBinding;
        Assert.IsTrue(dataBinding != null);
        Assert.IsTrue(each != null);

        Assert.AreEqual(1, each.Templates.Count);
    }
}
