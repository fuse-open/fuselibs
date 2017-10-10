var Observable = require("FuseJS/Observable");

var duration = Observable(0);

function updateDurationText() {
	duration.value = _video.getDuration();
}

function resume() {
	_video.resume();
}

function pause() {
	_video.pause();
}

function stop() {
	_video.stop();
}

module.exports = {
	duration: duration,
	updateDurationText: updateDurationText,
	resume: resume,
	pause: pause,
	stop: stop
};
