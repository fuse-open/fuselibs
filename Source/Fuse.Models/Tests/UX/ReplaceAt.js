var expectEval = true;
var feedTheCat;

class TodoItem {
	constructor(desc) {
		this.description = desc;
		this.isDone = false;
	}
}

class TodoList {
	constructor() {
		this.todos = [
			new TodoItem("Buy milk"),
			new TodoItem("Feed the cat")
		]
	}

	get todosRemaining() {
		if (!expectEval) { throw new Error() }
		if (this.todos[1] !== feedTheCat) { expectEval = false; }
		return this.todos.filter(x => !x.isDone).length
	}
}

export default class ReplaceAt {
	constructor() {
		this.todoList = new TodoList()
		this.feedTheCat = feedTheCat = this.todoList.todos[1]
	}

	replaceTodo() {
		this.todoList.todos[1] = new TodoItem("Haha!")
	}

	changeFeedTheCat() {
		this.feedTheCat.isDone = false;
	}
}