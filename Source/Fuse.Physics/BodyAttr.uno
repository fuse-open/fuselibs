using Uno.UX;

namespace Fuse.Physics
{
    public static class BodyAttr
    {
        [UXAttachedPropertyGetter("Physics.Friction")]
        public static float GetFriction(Visual n)
        {
            return Body.GetFriction(n);
        }

        [UXAttachedPropertySetter("Physics.Friction")]
        public static void SetFriction(Visual n, float friction)
        {
            Body.SetFriction(n, friction);
        }
    }
}
