let throwOnParentGetter = false;
class Parent {
	constructor(child) {
		this.child = child;
	}

	get foo() {
		if(throwOnParentGetter)
			throw new Error("Evaluated getter of dangling parent.");
	}
}

class Child {
	constructor() {
		this.data = "foo";
	}
}

export default class Root {
	constructor() {
		this.child = new Child();
		this.parent = new Parent(this.child);
	}

	step1() {
		this.parent.child = 0;
		// Change root.parent.child to be a primitive value (not an object).
		// This would trigger a bad code path in the differ where the parent
		// would be left dangling in the child's parent list.
	}

	step2() {
		throwOnParentGetter = true;
		this.child.data = "bar";
		// Change something to trigger re-evaluation of getters upwards the parent graph.
		// If <parent> was left dangling as a parent of <child>, its getters
		// will also be re-evaluated, which will throw an error and fail the test.
	}
}