
class PromiseTest {
    constructor() {
        this.resolve = () => { throw new Error("Shouldn't happen!"); }
        this.result = new Promise((resolve, reject) => {
            setTimeout(() => {
                resolve("yay!")
                console.log("Resovled!")
            }, 0);
        })
    }

    changePromise() {
        this.result = new Promise((resolve, reject) => {
            this.resolve = resolve;
        })
    }

    resolveNow() {
        this.resolve("hoho!");
    }
}

module.exports = PromiseTest;