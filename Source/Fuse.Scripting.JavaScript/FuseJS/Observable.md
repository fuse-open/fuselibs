
## Observable class

Represents a value that can be observed.

Observables serve many purposes in FuseJS:
* Reactive programming
* Dynamic data-binding to user interfaces
* Asynchronous programming  

Observables can hold a single value, or be treated a list of values with 0 or more elements.

### Creating observables

Observables are created by calling the `Observable` function with zero or more initial values.

* `Observable(<initial values>)` - constructor

Examples:

	var emptyObservable = Observable();

	var isSomethingEnabled = Observable(true);

	var friends = Observable("Jake", "Jane", "Joe");
	

### Observable values 
When an `Observable` contains a single value, we use the `.value` property to get or set
the value.   
 
* `.value` - gets or sets the value at index 0

Examples:

	if (isSomethingEnabled.value)
	{
		doSomething();
	}
	
	isSomethingEnabled.value = false;

### Observable lists

When an `Observable` represents a list of values, we use the following functions to
manipulate the values:

* `.length` - returns the number of values in the list
* `.getAt(index)` - returns the value at the given `index`
* `.add(value)` - adds `value` to the list
* `.remove(value)` - removes the first occurence of `value` from the list
* `.forEach(func)` - invokes `func` on every element in the list
* `.replaceAt(index, value)` - replaces the value at `index` with `value`
* `.replaceAll(array)` - replaces the list with elements from the `array`

Examples:

	friends.add("Gina");
	
	debug_log("I have " + friends.length + " friends");
	debug_log("My friend at index 1 is: " + friends.getAt(1));

	debug_log("This is my complete list of friends:");
	friends.forEach(function(x) {
		debug_log("* " + x);
	});


### Reactive programming
We say that Observables are _reactive_. This means that they can be _observed_ by _observers_. When the value of an `Observable` changes, the observers are notified about the change, and can update
their values accordingly.  

In a mobile app, we typically have a relatively simple core data model, and many derived values needed by
the UI which can be expressed as functions of the core data.

When we build apps with FuseJS, we start by identifing the values that make up the core data model.

Consider a simple TODO app as an example, consisting of a list of tasks. The core data model for this
app can look like this:

	function Task(description, assignedPerson, isDone)
	{
		this.description = description,
		this.assignedPerson = Observable(assignedPerson);
		this.isDone = Observable(isDone);
	}
	
	todoList = Observable(
		new Task("Buy milk", "Jane", false),
		new Task("Clean the kitchen", "Joe", false)
	);
	
We use observables to hold the data that can change over time. 

In the above example, what person is assigned to a task (`assignedPerson`), and whether the task is
completed (`isDone`), are values that can change. We wrap them in `Observable` objects to enable this.

Meanwhile, `description` is not wrapped in an `Observable`, hence we should not change that value after
we have created the `Task` object. If we do that, no other objects will be notified about the change.

The `todoList` itself is an observable list of values, as tasks can be added and removed from the 
list while the app is running. 

### Reactive operators

Reactive operators are methods on `Observable` that return new observables that compute new values
based on changes in the source.

These are some of the most important reactive operators:

* `.map(func)` - Returns a new observable where each value is mapped through `func`.
* `.where(condition)` - Returns a new observable with only the values for which `condition` is true.
* `.count()` - Returns the length of the observable as an observable number.
* `.count(condition)` - Returns an observable number of values for which `condition` is true

Say we want to compute a string which explains in natural language how many tasks are done
in our TODO app. We can then use the `count` and `map` operators:

	tasksDone = todoList.count(function(x) { return x.isDone; }); 
	
	tasksDoneText = tasksDone.map(function(x) { 
		return "There are " + x + " completed tasks."; 
	});

If we now modify the `todoList`,  `tasksDone` and `tasksDoneText` now know how to compute their
values automatically.

### Reactive expressions
The `Observable` class also ships with reactive math and logic operators. Thes operators takes value or another
observable as arguments. 

*Arithmetic*

* `.plus(x)` - computes the sum
* `.minus(x)` - computes the difference
* `.times(x)` - computes the product
* `.divide(x)` - computes the ratio

*Comparison* 

* `.greaterThan(x)`
* `.greaterThanOrEqualTo(x)`
* `.lessThan(x)`
* `.lessThanOrEqualTo(x)`
* `.equalTo(x)`
* `.notEqualTo(x)`

*Logic*
* `.or(x)` - Returns `true` if one of the operands are `true`, and `false` otherwise
* `.and(x)` - Returns `true` if both operands are `true`, and `false` otherwise
* `.xor(x)` - Returns `true` if the operands are not equal, and `false` otherwise
* `.not()` - Converts `true` to `false` and vice versa

Say for example we want to count the number of task that are *not* complete, we can simply use the `.not()` operator:

	tasksNotDone = todoList.count(function(x) { return x.isDone.not(); });
	
Let's count the number of incomplete tasks assigned to a specific person:

	currentPerson = Observable("Jane");

	remainingTasks = todoList.count(function(x) {
		return x.isDone.not()
		.and(x.assignedPerson.equalTo(currentPerson));
	};

### Subscribing to updates
The results of reactive operators will not be computed unless something is actually _subscribing_ 
to the results. We can do this using the following methods:

* `.addSubscriber(func)` - adds `func` to the list of functions that will be called when changes occur
* `.removeSubscriber(func)` - removes `func` from the list of funcitons that will be called when changes occur 

We can subscribe to the observables in our TODO app example to be notified when a value changes:

	tasksDoneText.addSubscriber(function() {
		debug_log(taskDoneText.value);
	};
	
You will get a callback immeditately when subscribing to an observable.

If we now add or remove elements from the TODO list, or change `isDone.value` on some of the tasks,
the above function will be called and log a message about the new status.


### Asynchronous programming
Observables can act as promises of data that will arrive later, allowing elegant handling of 
asynchronous operations. 

By using observables and reactive operators, we can write code in an uniform way without having to know 
if the data is immediately available or arrives later.

For example, the result of a HTTP request will not be immeditately available.

The following methods return observables of data from URL


### Observable metadata
Loading, progress, failed...
