"use strict";

var assert = require("assert");
var Observable = require("../../Observable.js");

describe('general observable tests', function() {
    it('test_01', function () {
        var tasks = Observable({name: "123 hi guys", isDone: false}, {name: "456 testing", isDone: true});

        var tasksDoneText = tasks.count(function(x){
            return x.isDone;
        }).map(function(x){
            return "There are " + x + " completed tasks";
        });
        tasksDoneText.addSubscriber(function(){
            //console.log(tasksDoneText.value);
        });

        assert.equal(tasksDoneText.value, "There are 1 completed tasks");

        tasks.replaceAt(0, {name: tasks.getAt(0).name, isDone: true});
        assert.equal(tasksDoneText.value, "There are 2 completed tasks");
    });
    it('test_02', function () {
        var fruits = Observable({name: "Apple", isGood: true}, {name: "Banana", isGood: true}, {name: "Pear", isGood: false}, {name: "Tomato", isGood: true});
        var goodFruits = fruits.where(function(e){ return e.isGood; });

        goodFruits.addSubscriber(function(){
            //console.log("Good fruits:");
            //goodFruits.forEach(function(e){
            //    console.log(e.name + " " + (e.isGood ? "is a good fruit" : "is not a good fruit, and should not of been on the list"));
            //});
        });

        assert.equal(fruits.length, 4);
        assert.equal(goodFruits.length, 3);

        fruits.add({name: "Grape", isGood: true});

        assert.equal(fruits.length, 5);
        assert.equal(goodFruits.length, 4);
    });
    it('test_03', function () {
        var books = Observable("UX and you", "Observing the observer", "Documenting the documenter");

        var numBooks = books.count();
        numBooks.addSubscriber(function(){
            //console.log("There are " + numBooks.value + " books. That is " + (numBooks.value == books.length ? "correct!" : "wrong!"));
        });

        assert.equal(numBooks.value, 3);

        books.remove(books.getAt(0));
        assert.equal(numBooks.value, 2);
    });
    it('test_04', function () {
        var beverages = Observable("Tea", "Coffee", "Milk");
        var snacks = Observable("Cake", "Biscuit", "General pastry");

        var beveragesPlusOne = Observable(function() { return beverages.length + 1; });
        var numProducts = Observable(function() { return beverages.length + snacks.length; });

        beveragesPlusOne.addSubscriber(function(){
            //console.log("There are " + beveragesPlusOne.value + " beverages if you add another. That is " + (beveragesPlusOne.value == beverages.length + 1 ? "correct." : "incorrect!"));
        });

        numProducts.addSubscriber(function(){
            //console.log("There are " + numProducts.value + " products. That is " + (numProducts.value == beverages.length + snacks.length ? "correct." : "incorrect!"));
        });

        assert.equal(beveragesPlusOne.value, 4);
        assert.equal(numProducts.value, 6);

        beverages.remove(beverages.getAt(0));
        assert.equal(beveragesPlusOne.value, 3);
        assert.equal(numProducts.value, 5);

        snacks.remove(snacks.getAt(0));
        assert.equal(beveragesPlusOne.value, 3);
        assert.equal(numProducts.value, 4);
    });
    it('test_05', function () {
        var people = Observable("Bob", "Jane", "Carl", "Tony", "Janice");

        var other_people = Observable("Mathew", "Jeff", "Stacey");

        var difference = Observable(function() { return people.length - other_people.length; });

        difference.addSubscriber(function(){
            //console.log("There are " + difference.value + " more people in the first people list. That is " + (difference.value == people.length - other_people.length ? "correct." : "incorrect."));
        });

        assert.equal(difference.value, 2);

        people.remove(people.getAt(0));
        assert.equal(difference.value, 1);

        other_people.remove(other_people.getAt(0));
        assert.equal(difference.value, 2);
    });
    it('test_06', function () {
        var days = Observable("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday");

        var numWeekdays = Observable(function() { return days.length - 2; });

        numWeekdays.addSubscriber(function(){
            //console.log("There are " + numWeekdays.value + " weekdays. That is " + (numWeekdays.value == days.length-1 ? "correct." : "incorrect."));
        });

        assert.equal(numWeekdays.value, 5);

        days.remove(days.getAt(0));
        assert.equal(numWeekdays.value, 4);
    });
    it('test_07', function () {
        var people = Observable("Bob", "Jane", "Carl", "Tony", "Janice");

        var other_people = Observable("Mathew", "Jeff", "Stacey");

        var difference = Observable(function() { return people.length - other_people.length; });

        difference.addSubscriber(function(){
            //console.log("The difference between the two lists is " + difference.value + ". That is " + (difference.value == people.value - other_people.value ? "correct." : "incorrect."));
        });

        assert.equal(difference.value, 2);

        people.remove(people.getAt(0));
        assert.equal(difference.value, 1);

        other_people.remove(other_people.getAt(0));
        assert.equal(difference.value, 2);
    });
    it('test_08', function () {
        var onTop = Observable("Butter", "Jam", "Cheese");

        var breadTypes = Observable("Wholegrain", "Wholemeal", "Multigrain");

        var breakfastCombinations = Observable(function() { return onTop.length * breadTypes.length; });

        breakfastCombinations.addSubscriber(function(){
            //console.log("There are " + breakfastCombinations.value + " combinations for breakfast. That is " + (breakfastCombinations.value == onTop.value * breadTypes.value ? "correct." : "incorrect!"));
        });

        assert.equal(breakfastCombinations.value, 9);

        onTop.remove(onTop.getAt(0));
        assert.equal(breakfastCombinations.value, 6);

        onTop.add("Butter");
        assert.equal(breakfastCombinations.value, 9);

        breadTypes.remove(breadTypes.getAt(0));
        assert.equal(breakfastCombinations.value, 6);
    });
    it('test_09', function () {
        var projects = Observable("Fix tickets", "Finalize design", "Debug backend");
        var estNeededPeople = Observable(function() { return projects.length * 2; });

        estNeededPeople.addSubscriber(function(){
            //console.log("Estimated people: " + estNeededPeople.value + ". That is " + (estNeededPeople.value == 6 ? "correct." : "incorrect!"));
        });

        assert.equal(estNeededPeople.value, 6);

        projects.remove(projects.getAt(0));
        assert.equal(estNeededPeople.value, 4);
    });
    it('test_10', function () {
        var number = Observable(10);

        var isNumberLarge = Observable(function() { return number.value > 5; });

        isNumberLarge.addSubscriber(function(){
            //console.log(number.value + " is " + (isNumberLarge.value ? "larger then " : "less then ") + "5. That is " + (isNumberLarge.value == (number.value > 5) ? "correct." : "incorrect!"));
        })

        assert.equal(isNumberLarge.value, true);

        number.value = 2;
        assert.equal(isNumberLarge.value, false);
    });
    it('test_11', function () {
        var staff = Observable("Jeff", "Gary", "Tara", "Nathan");

        var enoughStaff = Observable(function() { return staff.length > 2; });

        enoughStaff.addSubscriber(function(){
            //console.log("There is " + (enoughStaff.value ? "enough " : "not enough ") + "staff. That is " + (enoughStaff.value ? "correct" : "incorrect"));
        });

        assert.equal(enoughStaff.value, true);

        staff.remove(staff.getAt(0));
        assert.equal(enoughStaff.value, true);

        staff.remove(staff.getAt(0));
        assert.equal(enoughStaff.value, false);
    });
    it('test_12', function () {
        var price = Observable(15.4);
        var funds = Observable(20);

        var enoughMoney = Observable(function() { return funds >= price; });

        enoughMoney.addSubscriber(function(){
            //console.log("We " + (enoughMoney.value ? "have enough" : "do not have enough") + " money. That is " + (enoughMoney.value == (funds.value > price.value) ? "correct." : "incorrect!"));
        });

        assert.equal(enoughMoney.value, true);

        funds.value = 15;
        assert.equal(enoughMoney.value, false);
    });
    it('test_13', function () {
        var players = Observable("Bob", "Jebediah", "Laurie");

        var enoughPlayers = Observable(function() { return players.length >= 2; });

        enoughPlayers.addSubscriber(function() {
            //console.log("There are " + (enoughPlayers.value ? "enough" : "not enough") + " players. That is " + (enoughPlayers.value == (players.length > 2) ? "correct." : "incorrect!"));
        });

        assert.equal(enoughPlayers.value, true);

        players.remove(players.getAt(0));
        assert.equal(enoughPlayers.value, true);

        players.remove(players.getAt(0));
        assert.equal(enoughPlayers.value, false);
    });
    it('test_14', function () {
        var groupMembers = Observable("Serenity", "Samuel", "Landon", "Elmer");

        var spaceForMoreMembers = Observable(function() { return groupMembers.length < 5; });

        spaceForMoreMembers.addSubscriber(function() {
            //console.log("There " + (spaceForMoreMembers.value ? "is " : "is not ") + "space for more members. That is " + (spaceForMoreMembers.value == (groupMembers.length < 5) ? "correct." : "incorrect!"));
        });

        assert.equal(spaceForMoreMembers.value, true);

        groupMembers.add("Bobby");
        assert.equal(spaceForMoreMembers.value, false);
    });
    it('test_15', function () {
        var members = Observable("Landon", "Everett", "Mitchell", "Emily");

        var spaceOnOneScreen = Observable(function() { return members.length <= 5; });

        spaceOnOneScreen.addSubscriber(function(){
            //console.log("There " + (spaceOnOneScreen.value ? "is" : "is not") + " space on one screen for all the members. That is " + (spaceOnOneScreen.value == (members.length <= 5) ? "correct." : "incorrect!") );
        });

        assert.equal(spaceOnOneScreen.value, true);

        members.add("Bob");
        assert.equal(spaceOnOneScreen.value, true);

        members.add("Bobbie");
        assert.equal(spaceOnOneScreen.value, false);
    });
    it('test_16', function () {
        var firstGroup = Observable("Nelson", "Terrence", "Felicia");
        var secondGroup = Observable("Maxine", "Dora", "Camila", "Steve");

        var x = Observable(function() { return secondGroup.length <= firstGroup.length; });

        x.addSubscriber(function(){
            //console.log("The second group " + (x.value ? "is" : "is not") + " less than or equal to the first group. That is " + (x.value == (secondGroup.length <= firstGroup.length) ? "correct." : "incorrect!"));
        });

        assert.equal(x.value, false);

        secondGroup.remove(secondGroup.getAt(0));
        assert.equal(x.value, true);
    });
    it('test_17', function () {
        var userList1 = Observable("Elaine", "Lisa", "Taylor");
        var userList2 = Observable("Bob", "Jerome", "Scott");

        var sameSize = Observable(function() { return userList1.length == userList2.length; });

        sameSize.addSubscriber(function(){
            //console.log("The two lists " + (sameSize.value ? "are " : "are not ") + "the same size. This is " + ( sameSize.value == (userList1.length == userList2.length) ? "correct." : "incorrect!" ));
        });

        assert.equal(sameSize.value, true);

        userList1.add("Bob");
        assert.equal(sameSize.value, false);
    });
    it('test_18', function () {
        var fruits = Observable("Apple", "Pear", "Banana");

        var isThreeFruits = Observable(function() { return fruits.length == 3});

        isThreeFruits.addSubscriber(function(){
            //console.log("There " + (isThreeFruits.value ? "is " : "is not ") + "three fruits in the list. This is " + ( isThreeFruits.value == (fruits.length == 3) ? "correct." : "incorrect!" ));
        });

        assert.equal(isThreeFruits.value, true);

        fruits.add("Orange");

        assert.equal(isThreeFruits.value, false);
    });
    it('test_19', function () {
        var userList1 = Observable("Elaine", "Lisa", "Taylor");
        var userList2 = Observable("Bob", "Jerome", "Scott");

        var differentSize = Observable(function() { return userList1.length != userList2.length; });

        differentSize.addSubscriber(function(){
            //console.log("The two lists " + (differentSize.value ? "are " : "are not ") + "the same size. This is " + ( differentSize.value == (userList1.length != userList2.length) ? "correct." : "incorrect!" ));
        });

        assert.equal(differentSize.value, false);

        userList1.add("Bobbie");
        assert.equal(differentSize.value, true);
    });
    it('test_20', function () {
        var fruits = Observable("Apple", "Pear", "Banana");

        var isNotThreeFruits = Observable(function() { return fruits.length != 3; });

        isNotThreeFruits.addSubscriber(function(){
            //console.log("There " + (isNotThreeFruits.value ? "is " : "is not ") + "three fruits in the list. This is " + ( isNotThreeFruits.value == (fruits.length != 3) ? "correct." : "incorrect!" ));
        });

        assert.equal(isNotThreeFruits.value, false);

        fruits.add("Grape"); //Isn't this a berry?

        assert.equal(isNotThreeFruits.value, true);
    });
    it('test_21', function () {
        var appsMade = Observable(3);
        var yearsExperience = Observable(2);

        var qualifiesForBeta = Observable(function() { return appsMade.value >= 2 || yearsExperience.value >= 1; });

        qualifiesForBeta.addSubscriber(function(){
            //console.log("The user " + ( qualifiesForBeta.value ? "qualifies" : "does not qualify" ) + " for beta. This is " + ( qualifiesForBeta.value == (appsMade.value >=2) || (yearsExperience.value >= 1) ? "correct." : "incorrect!"));
        });

        assert.equal(qualifiesForBeta.value, true);

        appsMade.value = 1;
        assert.equal(qualifiesForBeta.value, true);

        yearsExperience.value = 0;
        assert.equal(qualifiesForBeta.value, false);

        appsMade.value = 3;
        assert.equal(qualifiesForBeta.value, true);

        yearsExperience.value = 1;
        assert.equal(qualifiesForBeta.value, true);
    });
    it('test_22', function () {
        var userPreference = Observable(false);

        var allwaysTrue = Observable(function() { return userPreference.value || true; });

        allwaysTrue.addSubscriber(function() {
            //console.log("allwaysTrue is " + allwaysTrue + ". That is " + (allwaysTrue.value ? "correct." : "incorrect"));
        });

        assert.equal(allwaysTrue.value, true);

        userPreference.value = true;

        assert.equal(allwaysTrue.value, true);
    });
    it('test_23', function () {
        var acceptedLicenceTerms = Observable(true);
        var correctDetails = Observable(true);

        var canRegister = Observable(function() { return acceptedLicenceTerms.value && correctDetails.value; });

        canRegister.addSubscriber(function() {
            //console.log("The user " + (canRegister.value ? "can " : "can not ") + "register. This is " + (canRegister.value == (acceptedLicenceTerms.value && correctDetails.value) ? "correct." : "incorrect!"));
        });

        assert.equal(canRegister.value, true);

        acceptedLicenceTerms.value = false;
        assert.equal(canRegister.value, false);

        correctDetails.value = false;
        assert.equal(canRegister.value, false);

        acceptedLicenceTerms.value = true;
        assert.equal(canRegister.value, false);

        correctDetails.value = true;
        assert.equal(canRegister.value, true);
    });
    it('test_24', function () {
        var value = Observable(true);

        var uselessAnd = Observable(function() { return value && false; });

        uselessAnd.addSubscriber(function() {
            //console.log("The useless and is " + uselessAnd.value + ". This is " + (uselessAnd.value == false ? "correct." : "incorrect!"));
        });

        assert.equal(uselessAnd.value, false);

        value.value = false;

        assert.equal(uselessAnd.value, false);
    });
    it('test_25', function () {
        var falseValue = Observable(false);

        var trueValue = falseValue.not();

        trueValue.addSubscriber(function(){
            //console.log("The not() value is " + trueValue.value + ". That is " + (trueValue.value == !falseValue.value ? "correct." : "incorrect!"));
        });
        assert.equal(trueValue.value, true);

        falseValue.value = true;

        assert.equal(trueValue.value, false);
    });
    it('test_26', function () {
        var list = Observable(10, 46, 35, 32, 52);

        assert.equal(list.length, 5);

        list.removeWhere(function(x) {
            return x < 35;
        });

        assert.equal(list.length, 3);
    });
    it('test_27', function () {
        var newList = Observable("a", "b", "c");

        assert.equal(newList.getAt(0), "a");

        newList.replaceAll(["d", "e", "f"]);
        assert.equal(newList.getAt(0), "d");
        assert.equal(newList.getAt(1), "e");
        assert.equal(newList.getAt(2), "f");
    });
    it('test_28', function () {
        var callCount = 0;
        var oneTimeTrigger = Observable(10);

        var detectorFunction = function() {
            callCount++;
        };

        oneTimeTrigger.addSubscriber(detectorFunction);
        assert.equal(callCount, 1);

        oneTimeTrigger.value = 2;
        assert.equal(callCount, 2);

        oneTimeTrigger.removeSubscriber(detectorFunction);
        oneTimeTrigger.value = 10;
        assert.equal(callCount, 2);
    });
    it('test_29', function() {
	/*
	var arrayInObservable = Observable([1, 2, 3]);
	assert.equal(arrayInObservable.length, 1);

	var expandedObservable = arrayInObservable.expand();
	assert.equal(expandedObservable.length, 3);

	arrayInObservable.getAt(0).splice(1,1);
	assert.equal(expandedObservable.length, 2);
	*/
    });
    it('test_30', function() {
	var testObservable = Observable(1, "two", "3");
	assert.equal(testObservable.toString(), "(observable) 1,two,3");
    });

    it('test_32', function() {
	/*
	var rootObservable = Observable(1);
	var filteredObservable = rootObservable.filter(function(x){
	    return x%2==1;
	});

	assert.equal(filteredObservable.value, 1);
	rootObservable.value = 2;
	assert.equal(filteredObservable.value, 1);
	rootObservable.value = 3;
	assert.equal(filteredObservable.value, 3);
	*/
    });
    it('test_33', function() {
        var obs = Observable(0, 10, 20, 30);
        var imapped = obs.map(function (x, i) { return x + i; });
        var imappedCorrect = function() {
            assert.equal(imapped.length, obs.length);
            for (var i = 0; i < imapped.length; ++i) {
                assert.equal(imapped.getAt(i), obs.getAt(i) + i);
            }
        }

        imapped.addSubscriber(function() {});
        imappedCorrect();

        for (var i = 0; i < 4; ++i)
        {
            obs.replaceAt(i, i * 100);
            imappedCorrect();
        }

        for (var i = 0; i < 4; ++i)
        {
            obs.removeAt(i);
            imappedCorrect();
            obs.add(i + 1000);
            imappedCorrect();
        }
    });
    it('test_34', function() {
        var obs = Observable("ha", "ka", "nya", "la", "pa", "nah");
        var obs_derived = obs.where(function(x) { return x.length == 3; });
        obs_derived.addSubscriber(function(x){});

        var expected = ["nya", "nah"];
        assert.equal(obs_derived.length, 2);
        for(var i = 0; i < expected.length; i++) {
            assert.equal(obs_derived.getAt(i), expected[i]);
        }
    });
    it('test_35', function() {
        var obs = Observable("foo", "boo");
        var obs_derived = obs.where(function(x) {return x.indexOf("o") != -1});
        obs_derived.addSubscriber(function(x){});

        obs.insertAll(1, ["who", "bar"]);

        //Stage 1: Test that the original observable contains expected stuff
        var expected = ["foo", "who", "bar", "boo"];
        for(var i = 0; i < expected.length; i++) {
            assert.equal(obs.getAt(i), expected[i]);
        }

        var deriv_expected = ["foo", "who", "boo"];
        for(var i = 0; i < deriv_expected.length; i++) {
            assert.equal(obs_derived.getAt(i), deriv_expected[i]);
        }
    });
    it('test_36', function() {
        var obs = Observable("ha", "ka", "nya", "la", "pa", "nah");
        var obs_derived = obs.where(function(x) { return x.length == 3; });
        obs_derived.addSubscriber(function(x){});

        assert.equal(obs_derived.length, 2);
        obs.removeRange(1, 3);
        var expectedNormal = ["ha", "pa", "nah"];
        for(var i = 0; i < expectedNormal.length; i++) {
            assert.equal(obs.getAt(i), expectedNormal[i]);
        }
        assert.equal(obs_derived.length, 1);
        assert.equal(obs_derived.getAt(0), "nah")
    });
    it('test_37', function() {
        var obs = Observable("one", "two");
        var obs_derived = obs.where(function(x) {return x.indexOf("o") != -1});
        obs_derived.addSubscriber(function(x){});

        obs.add("three");
        assert.equal(obs.length, 3);
        assert.equal(obs.getAt(2), "three");
        assert.equal(obs_derived.length, 2);
        assert.equal(obs_derived.getAt(0), "one");
        assert.equal(obs_derived.getAt(1), "two");
    });
    it('test_38', function() {
        var obs = Observable("one", "two", "three");
        var obs_derived = obs.where(function(x) {return x.indexOf("o") != -1});
        obs_derived.addSubscriber(function(x){});

        assert.equal(obs_derived.getAt(0), "one");
        assert.equal(obs_derived.getAt(1), "two");
        assert.equal(obs_derived.length, 2);

        obs.insertAt(1, "four");

        var expectedNormal = ["one", "four", "two", "three"];
        for(var i = 0; i < expectedNormal.length; i++) {
            assert.equal(obs.getAt(i), expectedNormal[i]);
        }
    });
    it('test_39', function() {
        var obs = Observable("one", "two", "three");
        var obs_derived = obs.where(function(x) {return x.indexOf("o") != -1});
        obs_derived.addSubscriber(function(x){});

        assert.equal(obs_derived.length, 2);
        obs.removeAt(1);

        assert.equal(obs.length, 2);
        assert.equal(obs.getAt(0), "one");
        assert.equal(obs.getAt(1), "three");

        assert.equal(obs_derived.length, 1);
        assert.equal(obs.getAt(0), "one");
    });
    it('test_42', function() {
        var obs = Observable("one", "two", 3);
        var identityObs = obs.identity();
        identityObs.addSubscriber(function(x){});

        var expectedValues = ["one", "two", 3];
        for(var i = 0; i < expectedValues.length; i++) {
            assert.equal(identityObs.getAt(i), expectedValues[i]);
        }

        obs.replaceAt(1,"foo");
        expectedValues = ["one", "foo", 3];
        for(var i = 0; i < expectedValues.length; i++) {
            assert.equal(identityObs.getAt(i), expectedValues[i]);
        }
    });
    it('test_twoWayMap_1', function() {
        var date_padded = new Observable(new Observable(new Date()));
        //This test will fail if the day changes between these two functions
        var real_date = new Date();
        var date = date_padded.inner();

        var day = date.twoWayMap(function(dt) { return dt.getDate(); }, function(d, dt) { dt.setDate(d); return dt; });

        day.addSubscriber(function(x){});

        assert.equal(day.value, real_date.getDate());

        day.value = 27;
        assert.equal(date_padded.value.value.getDate(), 27);
    });
    it('test_setInnerValue_1', function() {
        var val_padded = new Observable(new Observable(1));
        //This test will fail if the day changes between these two functions
        var val = val_padded.innerDeprecated();
        val.addSubscriber(function(x){});

        val.setInnerValue(2);

        assert.equal(val.value, 1);
        assert.equal(val_padded.value.value, 2);
    });
    it('test_filters_1', function() {
        var obs = Observable({name: "potato"}, {name: "potayto"}, {name: "potooto"}, {name: "potato"});
        assert.equal(obs.length, 4);

        var obs_filtered = obs.where({name: "potato"});
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.length, 2);

        obs.add({name: "potato"});
        assert.equal(obs_filtered.length, 3);
    });
    it('test_filters_2', function() {
        var obs = Observable({name: "potato"}, {name: "potayto"}, {name: "potooto"}, {name: "potato"});
        assert.equal(obs.length, 4);

        var obs_filtered = obs.count({name: "potato"});
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.value, 2);

        obs.add({name: "potato"});
        assert.equal(obs_filtered.value, 3);
    });
    it('test_filters_3', function() {
        var obs = Observable({name: "potato"}, {name: "potayto"}, {name: "potooto"}, {name: "potato"});

        var obs_filtered = obs.any({name: "not a potato"});
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.value, false);

        obs.add({name: "not a potato"});
        assert.equal(obs_filtered.value, true);
    });
    it('test_filters_4', function() {
        var obs = Observable({id: 1}, {id: 2}, {id: 3}, {id: 4});

        var obs_filtered = obs.first();
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.value.id, 1);

        obs.removeAt(0);
        assert.equal(obs_filtered.value.id, 2);
    });
    it('test_filters_5', function() {
        var obs = Observable({id: 1}, {id: 2}, {id: 3}, {id: 4});

        var obs_filtered = obs.last();
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.value.id, 4);

        obs.removeAt(3);
        assert.equal(obs_filtered.value.id, 3);
    });
    it('test_filters_6', function() {
        var obs = Observable({id: 1, value: "foo"}, {id: 2, value: "foo"}, {id: 3, value: "bar"}, {id: 4, value: "par"});

        var obs_filtered = obs.first({value: "foo"});
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.value.id, 1);

        obs.removeAt(0);
        assert.equal(obs_filtered.value.id, 2);

        obs_filtered = obs.first({value: "bar"});
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.value.id, 3);
    });
    it('test_filters_7', function() {
        var obs = Observable({id: 1, value: "foo"}, {id: 2, value: "foo"}, {id: 3, value: "bar"}, {id: 4, value: "par"});

        var obs_filtered = obs.last({value: "foo"});
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.value.id, 2);

        obs.removeAt(1);
        assert.equal(obs_filtered.value.id, 1);

        obs_filtered = obs.last({value: "bar"});
        obs_filtered.addSubscriber(function() {});
        assert.equal(obs_filtered.value.id, 3);
    });
});
