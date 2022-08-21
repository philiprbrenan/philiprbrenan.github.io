/*------------------------------------------------------------------------------
Javascript basics
Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2022
------------------------------------------------------------------------------*/
function dump(i)                                                                // Dump a data structure
 {const m = new Map()                                                           // Prevent recursion

  function dump2(i, d)                                                          // Dump a data structure
   {if (i === null)               return "null"                                 // Null
    if (i === undefined)          return "undefined"                            // Undefined
    if (typeof(i) === "function") return "function"                             // Function
    if (typeof(i) !== "object")   return i                                      // Non object

    if (m.get(i))                 return "recurse"                              // Stop attempt to recursion into an object already seen
    m.set(i, true)                                                              // Print on first pass

    const a = []                                                                // Array of sub prints

    function dumpKey(j, k, t, T)                                                // Dump a key value pair
     {const s = "   ".repeat(d)                                                 // Current spacing
      if (!m.get(k))
       {if (k === null)                                                         // Null
         {a.push(s+"\""+j+"\" : null\n")
         }
        else if (k === undefined)                                               // Undefined
         {a.push(s+"\""+j+"\" : undefined\n")
         }
        else if (typeof(k) === "function")                                      // Function
         {a.push(s+"\""+j+"\" : function\n")
         }
        else if (Array.isArray(k))                                              // Array
         {a.push(s+"\""+j+"\" :\n"+dump2(k, d+1))
         }
        else if (typeof(k) !== "object")                                        // Non object
         {a.push(s+"\""+j+"\" : " + k+"\n")
         }
        else
         {a.push(s+"\""+j+"\" : "+t+"\n"+s+dump2(k, d+1)+s+T+"\n")              // Key with object as value
         }
       }
      else
       {a.push(s+"\""+j+"\" : recurse\n")                                       // Prevent recursion
       }
     }

    if (Array.isArray(i))                                                       // Array
     {for(const j of i)
       {a.push("  ".repeat(d)+"["+dump2(j)+"]")
       }
     }
    else if (Object.getPrototypeOf(i) === Map.prototype)                        // Map
     {for(const j of i.keys())
       {dumpKey(j, i.get(j), "new Map(", ")")
       }
     }
    else                                                                        // Object in general
     {for(const j of Object.keys(i).sort())
       {dumpKey(j, i[j], "{", "}")
       }
     }
    return a.join(" ")
   }
  return dump2(i, 0)
 }

function say()                                                                  // Say something
 {const a = []
  for(const i of arguments) a.push(dump(i))
  console.log(a.join(' '))
 }

function stop()                                                                 // Say something
 {say(...arguments)
  console.trace()
 }

var is_deeply_tests_passed = 0;                                                 // The number of is deeply tests passed

function is_deeply(got, expected)                                               // Compare whet we got with what we expected
 {if (arguments.length != 2) stop("Two arguments required");                    // Must have two parameters

  function pass()
   {say("is_deeply", is_deeply_tests_passed, "passed");
    return true;
   }

  is_deeply_tests_passed++
  if (Array.isArray(got) && Array.isArray(expected))                            // Compare two arrays
   {if (got.length != expected.length)
     {return stop("Lengths do not match: ", got.length, "versus", expected.length)
     }
    for(var i = 0; i < got.length; ++i)
     {if (got[i] != expected[i])
       {return stop("Mismatch at index", i, "got:", got[i], "expected:", expected[i])
       }
     }
    return pass()
   }

  if (typeof(got) == "string" && typeof(expected) == "string")                  // Compare two strings
   {if (got.length != expected.length)
     {console.log("AAAA", got, expected)
       return stop("Lengths do not match: ", got.length, "versus", expected.length)
     }
    for(var i = 0; i < got.length; ++i)
     {if (got[i] != expected[i])
       {return stop("Mismatch at index", i, "got:", got[i], "expected:", expected[i])
       }
     }
    return pass()
   }

  if (typeof(got) == "number" && typeof(expected) == "number")                  // Compare two numbers
   {if (got != expected)
     {return stop("Number ", got, "does not equal", expected)
     }
    return pass()
   }

  if (typeof(got) == "boolean" && typeof(expected) == "boolean")                // Compare two booleans
   {if (got != expected)
     {return stop("Boolean ", got, "does not equal", expected)
     }
    return pass()
   }

  if (Object.getPrototypeOf(got)      === Map.prototype &&                      // Compare two maps
      Object.getPrototypeOf(expected) === Map.prototype)
   {if (got.size != expected.size)
     {return stop("Maps have different sizes:", got.size, "versus", expected.size())
     }
    for(const g of got.keys())
     {if (got.get(g) != expected.get(g))
       {return stop("Mismatch at index", g, "got:", got.get(g), "expected:", expected.get(g))
       }
     }
    return pass()
   }

  stop("Cannot compare these two types: ", dump(got), dump(expected));
 }

function LinkedList()                                                           // Linked list as a function
 {const l = this

  l.putFirst = (value) =>                                                       // Put a value onto the front of the list
   {const e = new Element(value)
    if (l.first == null) l.first = l.last = e
    else
     {(l.first.prev = e).next = l.first
      l.first = l.first.prev
     }
    return e
   }

  l.putLast = (value) =>                                                        // Put a value onto the end of the list
   {const e = new Element(value)
    if (l.first == null) l.first = l.last = e
    else
     {(l.last.next = e).prev = l.last
      l.last = l.last.next
     }
    return e
   }

  l.unshift = value => l.putFirst(value)                                        // Push a value onto the front of the list
  l.push    = value => l.putLast(value)                                         // Push a value onto the end of the list
  l.pop = () => l.last == null ? null : l.last.remove().value                   // Pop the value off the end of the list
  l.shift = () => l.first == null ? null : l.first.remove().value               // Shift the value off the front of the list

  l.print = () =>                                                               // Print the list
   {for(let p = l.first; p != null; p = p.next) say(p.value)
   }

  l.string = () =>                                                              // Stringify the values in the list
   {const s = []
    for(let p = l.first; p != null; p = p.next) s.push(dump(p.value))
    return s.join(" ")
   }

  l.size = () =>                                                                // Size of the list
   {let n = 0
    for(let p = l.first; p != null; p = p.next) ++n
    return n
   }

  function Element(value)                                                       // Element of linked list
   {this.value = value; this.next  = this.prev = null;
    this.remove = () =>                                                         // Remove this element from the list
     {const e = this
      if (e === l.first && e === l.last)
       {l.first = l.last = null
        return e
       }
      if (e === l.first)
       {l.first = e.next
        l.first.prev = null
        return e
       }
      if (e === l.last)
       {l.last = e.prev
        l.last.next = null
        return e
       }
      e.prev.next = e.next
      e.next.prev = e.prev
      return e
     }

    this.putNext = (value) =>                                                   // Put a value after the specified value
     {const e = new Element(value)
      if (this.next === null) {this.next = e; e.prev = this; l.last = e}
      else
       {e.next = this.next; e.prev = this; this.next.prev = e; this.next = e;
       }
      return e
     }

    this.putPrev = (value) =>                                                   // Put a value before the specified value
     {const e = new Element(value)
      if (this.prev === null) {this.prev = e; e.next = this; l.first = e}
      else
       {e.prev = this.prev; e.next = this; this.prev.next = e; this.prev = e;
       }
      return e
     }
   }
 }

if (0)                                                                          // Tests for is_deeply
 {say("a", "b", "c");
  const o = new Map([['a', 11], ['b', 22]])
  const p = new Map([['a', 11], ['b', 33]])
  say(o)
  is_deeply(o, p)
  is_deeply([1,2], [1,3])
  is_deeply([1,2], [1,2])
  is_deeply([1,2], [1,3])
 }

if (0)                                                                          // Tests for linked list function
 {const l = new LinkedList()
  for(let i = 0; i < 9; ++i) l.push(i)
  is_deeply(l.first.value,      0)
  is_deeply(l.first.next.value, 1)
  is_deeply(l.last.prev.value,  7)
  is_deeply(l.last.value,       8)
  is_deeply(l.size(), 9)
  is_deeply(l.string(), "0 1 2 3 4 5 6 7 8")
  is_deeply(l.pop(), 8)
  is_deeply(l.size(), 8)
  is_deeply(l.string(), "0 1 2 3 4 5 6 7")
  const b = l.last
  const c = b.putPrev(73).putPrev(71).putNext(72)
  is_deeply(l.string(), "0 1 2 3 4 5 6 71 72 73 7")
  c.remove()
  is_deeply(l.string(), "0 1 2 3 4 5 6 71 73 7")
//  say(l)
 }

function Hash()                                                                 // Hash table
 {const h = this
  h.size = 0                                                                    // Number of elements in the hash table
  h.arenaSize = 1                                                               // Size of arena
  h.keys = [null]                                                               // Keys arena
  h.data = [null]                                                               // Data arena

  this.hash = (key) =>                                                          // Hash a string
   {let n = 0;
    for(let i = 0; i < key.length; ++i)
     {n = (n + key.charCodeAt(i)) ** 2 % h.arenaSize
     }
    return n
   }

  this.reallocate = () =>                                                       // Reallocate the arena
   {const n = h.arenaSize; const N = 2 * n; const k = h.keys; const d = h.data
    h.keys = []; for(let i = 0; i < N; ++i) h.keys[i] = null
    h.data = []; for(let i = 0; i < N; ++i) h.data[i] = null
    h.arenaSize = N
    h.size = 0

    for(let i = 0; i < n; ++i)
     {if (k[i] !== null)
       {h.put(k[i], d[i])
       }
     }
   }

  this.put = (key, data) =>                                                     // Put a key value pair
   {if (2 * h.size + 1 >= h.arenaSize) h.reallocate()
    h.size++
    const n = h.hash(key)
    for(let i = 0; i < h.arenaSize; ++i)
     {const j = n + i
      if (h.keys[j] === null || h.keys[j] == key)
       {h.keys[j] = key
        h.data[j] = data
        return
       }
     }
   }

  this.get = (key) =>                                                           // Get the value associated with the key
   {const n = h.hash(key)
    for(let i = 0; i < h.arenaSize; ++i)
     {const j = n + i
      if (h.keys[j] == key)  return h.data[j]
      if (h.keys[j] == null) return null
     }
   }
 }

if (0)                                                                          // Tests for linked list function
 {const h = new Hash()
  h.put("a",    "A")
  h.put("b",    "B")
  h.put("ab",   "AB")
  h.put("abc",  "ABC")
  h.put("abcd", "ABCD")
  is_deeply(h.size, 5)
  is_deeply(h.arenaSize, 16)
  is_deeply(h.get("a"   ), "A"   )
  is_deeply(h.get("b"   ), "B"   )
  is_deeply(h.get("ab"  ), "AB"  )
  is_deeply(h.get("abc" ), "ABC" )
  is_deeply(h.get("abcd"), "ABCD")
 }

module.exports = { say, stop, is_deeply, dump, LinkedList, Hash }
