## The "rooted" concept

Nodes can be *rooted* within an @App. This means that they form part of the subtree currently
connected to the @App singleton. In the following example, the @Panel and @Rectangle are always
rooted:

	<App>
		<Panel>
			<Rectangle />
		</Panel>
	</App>

When a node	is removed from a rooted tree, it becomes *unrooted*.

While rooted, nodes have a @Parent. Only @Visual nodes can be parents of other nodes. However, 
@Behaviors may contain other nodes in UX markup. In the following example, the @WhilePressed
(which is a @Behavior) contains a @Circle. The @Circle is not rooted by default.

	<Panel>
		<WhilePressed>
			<Circle />
		</WhilePressed>
	</Panel>

While the @Panel is pressed, the @Circle is added to the @Panel. Assuming the @Panel is rooted,
this will make the @Circle *rooted*. When the @Panel is no longer pressed, the @Circle is removed
from the @Panel, *unrooting* the @Circle.