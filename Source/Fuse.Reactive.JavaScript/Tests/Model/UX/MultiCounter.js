var Counter = require("./MultiCounter_Counter");

class MultiCounter {
    constructor() {
        this.counters = [ new Counter() ];
    }

    addCounter() {
        this.counters.push(new Counter());
    }

    removeCounter() {
        this.counters.pop();
    }
};

module.exports = MultiCounter;