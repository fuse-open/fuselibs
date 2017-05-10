function require(x)
{
	if (x === "FuseJS/Observable" || x === "../../Observable.js") return Observable;
	else if (x === "FuseJS/Fetch" || x === "../../Fetch.js") return Fetch;
    else if (x === "FuseJS/FetchJson" || x === "../../FetchJson.js") return FetchJson;
	else if (x === "assert") return assert;

	throw new Error("module not found: " + x);
}

module = {};
module.exports = {}