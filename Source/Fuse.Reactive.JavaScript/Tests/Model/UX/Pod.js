class ModelPod {
	constructor() {
		this.data = {
			value: "a",
			nest: {
				value: "b",
			}
		}
	}
	
	step1() {
		this.data.value = "c"
	}
	
	step2() {
		this.data.nest.value = "d"
	}
	
	step3() {
		this.data.nest = {
			value: "e"
		}
	}
}

module.exports = ModelPod