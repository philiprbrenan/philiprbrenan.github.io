const {say, is_deeply} = require("../basics.js")
const a = new Map()

a.set("a", 1)
a.set("b", 2)

is_deeply(a.get("a"), 1)
is_deeply(a.get("b"), 2)
is_deeply(a, new Map([["a", 1], ["b", 2]]))
