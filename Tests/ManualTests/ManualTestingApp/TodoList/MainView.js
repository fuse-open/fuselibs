var Observable = require("FuseJS/Observable");

function Task(title){
	var self = this;
	this.title = title;
}

var todoList = Observable();
var isRemoveAllVisible = Observable(function() {
	return todoList.length >= 5;
});

function addItem(arg) {
	todoList.add(new Task("Some item " + (todoList.length + 1)));
}

function deleteAllItems() {
	while (todoList.length > 0) {
		todoList.removeAt(0);
	}
}

module.exports = {
	todoList: todoList,
	isRemoveAllVisible: isRemoveAllVisible,
	addItem: addItem,
	deleteAllItems: deleteAllItems
};
