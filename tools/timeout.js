const m = 15

setTimeout(() => {
    console.error(`Timed out after running for ${m} minutes`)
    process.exit(1)
}, m * 60_000)
