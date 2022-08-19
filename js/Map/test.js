const {say} = require("../basics2.js")
const a = new Map()

a.set("a", 1)
a.set("b", 2)

say(a.get("a"))
say(a)
keys = a.keys()
for(const k of keys)
 {say(k)
 }
