export default class {
	get foo() {
		throw new Error("THROWN_FROM_GETTER");
	}
}