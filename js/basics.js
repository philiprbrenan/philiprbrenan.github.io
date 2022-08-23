/*------------------------------------------------------------------------------
Javascript basics: debugging, testing, data structures: lists, hashes, trees.
Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2022
------------------------------------------------------------------------------*/
function Testing(testing=false) {                                               // Testing name space

function dump(i)                                                                // Dump a data structure
 {const m = new Map()                                                           // Prevent recursion

  function dump2(i, d)                                                          // Dump a sub data structure
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
         {//a.push(s+"\""+j+"\" : function\n")                                  // Reduce clutter
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
     {const s = []
      for(const j of i) s.push(dump2(j))
      a.push("  ".repeat(d)+"["+s.join(", ")+"]\n")
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
  process.exit()
 }

let assert_tests_passed = 0                                                     // The number of asserts passed

function assert(condition)                                                      // Assert something
 {if (!condition)
   {console.trace()
    stop()
   }
  ++assert_tests_passed
 }

function equal(got, expected)                                                   // Compare what we got with what we expected
 {function pass()                                                               // Action on pass
   {return null
   }

  function fail(message)                                                        // Action on fail
   {return message
   }

  if (Array.isArray(got) && Array.isArray(expected))                            // Compare two arrays
   {if (got.length != expected.length)
     {return fail("Lengths do not match: ", got.length, "versus", expected.length)
     }
    for(var i = 0; i < got.length; ++i)
     {if (got[i] != expected[i])
       {return fail("Mismatch at index", i, "got:", got[i], "expected:", expected[i])
       }
     }
    return pass()
   }

  if (typeof(got) == "string" && typeof(expected) == "string")                  // Compare two strings
   {if (got.length != expected.length)
     {return fail("Lengths do not match: ", got.length, "versus", expected.length)
     }
    for(var i = 0; i < got.length; ++i)
     {if (got[i] != expected[i])
       {return fail("Mismatch at index", i, "got:", got[i], "expected:", expected[i])
       }
     }
    return pass()
   }

  if (typeof(got) == "number" && typeof(expected) == "number")                  // Compare two numbers
   {if (got != expected)
     {return fail("Number ", got, "does not equal", expected)
     }
    return pass()
   }

  if (typeof(got) == "boolean" && typeof(expected) == "boolean")                // Compare two booleans
   {if (got != expected)
     {return fail("Boolean ", got, "does not equal", expected)
     }
    return pass()
   }

  if (Object.getPrototypeOf(got)      === Map.prototype &&                      // Compare two maps
      Object.getPrototypeOf(expected) === Map.prototype)
   {if (got.size != expected.size)
     {return fail("Maps have different sizes:", got.size, "versus", expected.size())
     }
    for(const g of got.keys())
     {if (got.get(g) != expected.get(g))
       {return fail("Mismatch at index", g, "got:", got.get(g), "expected:", expected.get(g))
       }
     }
    return pass()
   }

  stop("Cannot compare these two types: ", dump(got), dump(expected));
 }

let is_deeply_tests_passed = 0;                                                 // The number of is deeply tests passed

function is_deeply(got, expected)                                               // Compare what we got with what we expected
 {const m = equal(got, expected);
  if (m === null) return ++is_deeply_tests_passed
  stop(m)
 }

let not_deeply_tests_passed = 0;                                                // The number of not deeply tests passed

function not_deeply(got, expected)                                              // Compare what we got with what we expected
 {const m = equal(got, expected);
  if (m === null) return stop("Unexpectedly equal")
  ++not_deeply_tests_passed
  return m
 }

function testResults()                                                          // Print testing results
 {say(`Passed ${assert_tests_passed} asserts,  ${is_deeply_tests_passed} is_deeply tests,  ${not_deeply_tests_passed} not_deeply tests`)
 }

function range(start, end)                                                      // Return a range of numbers as an array starting at 'start' and ending one before 'end'
 {const n = []
  for(let i = start; i < end; ++i) n.push(i)
  return n
 }

function LinkedList()                                                           // Linked lists
 {const l = this; l.first = l.last = null;

  l.putFirst = (value) =>                                                       // Put a value onto the front of the list
   {const e = new Element(value)
    if (l.first === null) l.first = l.last = e
    else
     {(l.first.prev = e).next = l.first
      l.first = l.first.prev
     }
    return e
   }

  l.putLast = (value) =>                                                        // Put a value onto the end of the list
   {const e = new Element(value)
    if (l.first === null) l.first = l.last = e
    else
     {(l.last.next = e).prev = l.last
      l.last = l.last.next
     }
    return e
   }

  l.unshift = value => l.putFirst(value)                                        // Push a value onto the front of the list
  l.push    = value => l.putLast(value)                                         // Push a value onto the end of the list
  l.pop = () => l.last === null ? null : l.last.remove().value                   // Pop the value off the end of the list
  l.shift = () => l.first === null ? null : l.first.remove().value               // Shift the value off the front of the list

  l.print = () =>                                                               // Print the list
   {for(let p = l.first; p !== null; p = p.next) say(p.value)
   }

  l.string = () =>                                                              // Stringify the values in the list
   {const s = []
    for(let p = l.first; p !== null; p = p.next) s.push(dump(p.value))
    return s.join(" ")
   }

  l.size = () =>                                                                // Size of the list
   {let n = 0
    for(let p = l.first; p !== null; p = p.next) ++n
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

    this.putNext = (value) =>                                                   // Put a value after the specified element
     {const e = new Element(value)
      if (this.next === null) {this.next = e; e.prev = this; l.last = e}
      else
       {e.next = this.next; e.prev = this; this.next.prev = e; this.next = e;
       }
      return e
     }

    this.putPrev = (value) =>                                                   // Put a value before the specified element
     {const e = new Element(value)
      if (this.prev === null) {this.prev = e; e.next = this; l.first = e}
      else
       {e.prev = this.prev; e.next = this; this.prev.next = e; this.prev = e;
       }
      return e
     }
   }
 }

if (testing)                                                                    // Tests for is_deeply
 {const o = new Map([['a', 11], ['b', 22]])
  const p = new Map([['a', 11], ['b', 33]])
  not_deeply(o, p)
  not_deeply([1,2], [1,3])
   is_deeply([1,2], [1,2])
  not_deeply([1,2], [1,3])
 }

if (testing)                                                                    // Tests for linked list
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
  h.arenaSize = 1                                                               // Size of arenas
  h.keys = [null]                                                               // Keys arena
  h.data = [null]                                                               // Data arena

  this.hash = (key) =>                                                          // Hash a string
   {let n = 0;
    for(let i = 0; i < key.length; ++i)
     {n = (n + key.charCodeAt(i)) ** 2 % h.arenaSize
     }
    return n
   }

  this.reallocate = () =>                                                       // Reallocate the arena to make it larger
   {const n = h.arenaSize; const N = 2 * n; const k = h.keys; const d = h.data
    h.keys = []; for(let i = 0; i < N; ++i) h.keys[i] = null
    h.data = []; for(let i = 0; i < N; ++i) h.data[i] = null
    h.arenaSize = N
    h.size = 0

    for(let i = 0; i < n; ++i)
     {if (k[i] !== null)
       {h.set(k[i], d[i])
       }
     }
   }

  this.set = (key, data) =>                                                     // Set the data associated with a key
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
      if (h.keys[j] ==  key)  return h.data[j]
      if (h.keys[j] === null) return null
     }
   }
 }

if (testing)                                                                    // Tests for hashing
 {const h = new Hash()
  h.set("a",    "A")
  h.set("b",    "B")
  h.set("ab",   "AB")
  h.set("ba",   "BA")
  h.set("abc",  "ABC")
  h.set("abcd", "ABCD")
  is_deeply(h.size, 6)
  is_deeply(h.arenaSize, 16)
  is_deeply(h.get("a"   ), "A"   )
  is_deeply(h.get("b"   ), "B"   )
  is_deeply(h.get("ab"  ), "AB"  )
  is_deeply(h.get("abc" ), "ABC" )
  is_deeply(h.get("abcd"), "ABCD")
 }

function Tree(N)                                                                // N/2-1 - N way trees with N at least 4. When N is 4 we get red-black trees by another name
 {if (N % 2) ++N;                                                               // Make N even - it is possible to operate with N odd but it is a lot of work for little gain
  const t = this
  t.N    = N                                                                    // N is the number of nodes, N-1 is the number of keys, N/2-1 are the left or right hand key set in a split
  t.root = null                                                                 // The current root node
  t.size = 0                                                                    // Number of elements in the tree

  this.set = (key, data) =>                                                     // Put a key value pair
   {if (t.root === null)                                                        // Empty tree
     {const e = t.root = new Element()
      e.keys.push(key); e.data.push(data)
      return
     }

    let q = null                                                                // Parent to merge into
    for (var p = t.root; p !== null; q = p, p = p.step(key))                    // Non empty tree
     {if (p.count() >= t.N - 1)                                                 // Split the node if possible
       {p.split()
        if (q !== null)                                                         // Merge split node back into preceding node
         {q.merge(p)
          p = q                                                                 // Restart from parent
         }
       }

      const f = p.check(key)
      if (f !== null)                                                           // Located the key
       {p.data[f] = data
        return
       }

      if (p.leaf())                                                             // On a leaf
       {const i = new t.Element();
        i.keys.push(key); i.data.push(data)
        p.mergeLeaf(key, data)
        return
       }
     }
    stop("Unreachable")
   }

  this.get = (key) =>                                                           // Get the data associated with a key or null if the key is not present in the tree
   {if (t.root === null) return null                                            // Empty tree
    for(var p = t.root; p !== null; p = p.step(key))                            // Non empty tree
     {const f = p.check(key)                                                    // Check for matching key
      if (f !== null) return p.data[f]                                          // Found a matching node
      if (p.leaf()) return null                                                 // On a leaf so no where else to search so the key is not present int the tree
     }
   }

  this.getFirst = () =>                                                         // Get the first key in a tree
   {return t.root === null ? null : t.root.getFirst()
   }

  this.getLast = () =>                                                          // Get the last key in a tree
   {return t.root === null ? null : t.root.getLast()
   }

  this.getNext = (key) =>                                                       // Get the next key after the specified one
   {if (t.root === null || key == t.root.getLast()) return null                 // Empty tree or last key
    for(var p = t.root; p !== null;)                                            // Non empty tree
     {const f = p.check(key)
      if (p.leaf())                                                             // Leaf node
       {return f < p.keys.length - 1 ? p.keys[f + 1] : null                     // Next from match on leaf as the key must exist in the leaf
       }
      if (f !== null) return p.nodes[f+1].getFirst()                             // Step through next node and go first - th node must exist because we are not on a leaf
      const F = p.firstGt(key)                                                  // Next larger key
      if (F === null)                                                            // Larger than all keys in node
       {p = p.nodes[p.nodes.length-1]                                           // Continue with last node
       }
      else                                                                      // Found a larger key
       {const q = p.nodes[F]                                                    // Left of next larger key
        if (key == q.getLast()) return p.keys[F]                                // Next greater key in this node is the next greter key because the current key is the key previous to the next greater key in this node
        p = q
       }
     }
   }

  this.keys = () =>                                                             // Get all the keys in a tree as an array
   {const k = []
    function add(element)                                                       // Add all the keys in each node recursively
     {k.push(...element.keys)
      for(const n of element.nodes) add(n)                                      // Each sub tree
     }
    if (t.root !== null) add(t.root)
    k.sort()
    return k
   }

  function Element()                                                            // Node of a tree
   {const e = this
    e.nodes = []
    e.keys  = []
    e.data  = []

    e.count = () => e.keys.length                                               // Count the keys in a node

    e.leaf  = () => e.nodes.length == 0                                         // Node is a leaf node

    e.split = () =>                                                             // Split a node
     {const l = new Element(), r = new Element(),
            N = t.N, n = N / 2, K = N - 1, k = n - 1
      assert(e.count() == K)
      for (let i = 0; i < k; ++i)                                               // Split keys and data
       {l.keys[i] = e.keys[i]
        l.data[i] = e.data[i]
        r.keys[i] = e.keys[n+i]
        r.data[i] = e.data[n+i]
       }
      if (!e.leaf())                                                            // Split nodes if not a leaf
       {for (let i = 0; i < n; ++i)
         {l.nodes[i] = e.nodes[i]
          r.nodes[i] = e.nodes[n+i]
         }
       }
      e.keys[0]  = e.keys[k]                                                    // Copy middle key and data
      e.data[0]  = e.data[k]
      e.keys.length = e.data.length = 1; e.nodes.length = 2
      e.nodes[0] = l
      e.nodes[1] = r
     }

    e.merge = (s) =>                                                            // Merge in a split node at the point at which the split node is referenced
     {const k = [], d = [], n = [], N = e.count()
      assert(s.count() == 1)                                                    // The node to be merged in can only have one key
      assert(N < t.N)                                                           // The node to merge to must have room for the key being merged in
      for(let i = 0; i < N; ++i)                                                // Each key
       {if (e.nodes[i] != s)                                                    // We have not yet reached the splitting
         {k.push(e.keys[i])
          d.push(e.data[i])
          n.push(e.nodes[i])
         }
        else                                                                    // Replace the referenced node with its sub nodes
         {k.push(s.keys [0]); k.push(e.keys[i])
          d.push(s.data [0]); d.push(e.data[i])
          n.push(s.nodes[0], s.nodes[1])
         }
       }
      if (e.nodes[N] == s)                                                      // The split node was last
         {k.push(s.keys [0])
          d.push(s.data [0])
          n.push(s.nodes[0], s.nodes[1])
       }
      else
       {n.push(e.nodes[N])                                                      // The split node was not last
       }
      e.keys = k; e.data = d; e.nodes = n
     }

    e.mergeLeaf = (key, data) =>                                                // Merge into a leaf
     {const k = [], d = [], N = e.count()
      assert(N < t.N)                                                           // The node to merge to must have room for the key being merged in
      for(let i = 0; i < N; ++i)                                                // Each key
       {if (e.keys[i] < key)                                                    // We have not yet reached the splitting
         {k.push(e.keys[i])
          d.push(e.data[i])
         }
        else                                                                    // Replace the referenced node with its sub nodes
         {k.push(key);  k.push(e.keys[i])
          d.push(data); d.push(e.data[i])
         }
       }
      if (key > k[N-1])                                                         // Larger than all keys
       {k.push(key)
        d.push(data)
       }
      e.keys = k; e.data = d;
     }

    e.check = (key) =>                                                          // Return the index of a key in a node or null if no such key
     {const N = e.count()
      for(let i = 0; i < N; ++i)                                                // Each key
       {if (e.keys[i] == key) return i                                          // Key has been found
       }
      return null
     }

    e.firstGt = (key) =>                                                        // Return the index of the first key greater than the specified key is such a key exists else null
     {const N = e.count()
      for(let i = 0; i < N; ++i)                                                // Each key
       {if (e.keys[i] > key) return i                                           // Greater key has been found
       }
      return null
     }

    e.step = (key) =>                                                           // Return the node reached by this key (which is assumed not to be equal to any existing key)
     {const N = e.count()
      for(let i = 0; i < N; ++i)                                                // Each key
       {if (key < e.keys[i]) return e.nodes[i]                                  // Smallest key that the current key is smaller than
       }
      return e.nodes[N]                                                         // Larger than all keys
     }

    e.getFirst = () =>                                                          // Get the first key in a tree
     {for(var p = e; p !== null; p = p.nodes[0])                                 // Non empty tree
       {if (p.leaf()) return p.keys[0]                                          // On a leaf
       }
     }

    e.getLast = () =>                                                           // Get the last key in a tree
     {for(var p = e; p !== null; p = p.nodes[p.nodes.length-1])                  // Non empty tree
       {if (p.leaf()) return p.keys[p.keys.length-1]                            // On a leaf
       }
     }
   }
  this.Element = Element;
 }

if (testing)                                                                    // Tests for Tree - split leaf
 {const t = new Tree(4), e = new t.Element();
  e.keys  = [1,2,3]
  e.data  = [11,22,33]

  e.split()

  is_deeply(e.count(),  1)
  is_deeply(e.keys[0],  2)
  is_deeply(e.data[0], 22)

  const f = e.nodes[0]
  is_deeply(f.count(),   1)
  is_deeply(f.keys [0],  1)
  is_deeply(f.data [0], 11)
  is_deeply(f.nodes.length,  0)

  const g = e.nodes[1]
  is_deeply(g.count(),   1)
  is_deeply(g.keys [0],  3)
  is_deeply(g.data [0], 33)
  is_deeply(g.nodes.length, 0)
 }

if (testing)                                                                    // Tests for Tree - split
 {const t = new Tree(4), e = new t.Element();
  e.keys  = [1,2,3]
  e.data  = [11,22,33]
  e.nodes = [0,1,2,3]

  e.split()

  is_deeply(e.count(),  1)
  is_deeply(e.keys[0],  2)
  is_deeply(e.data[0], 22)

  const f = e.nodes[0]
  is_deeply(f.count(),   1)
  is_deeply(f.keys [0],  1)
  is_deeply(f.data [0], 11)
  is_deeply(f.nodes[0],  0)
  is_deeply(f.nodes[1],  1)

  const g = e.nodes[1]
  is_deeply(g.count(),   1)
  is_deeply(g.keys [0],  3)
  is_deeply(g.data [0], 33)
  is_deeply(g.nodes[0],  2)
  is_deeply(g.nodes[1],  3)
 }

if (testing)                                                                    // Tests for Tree - check, step
 {const t = new Tree(4), e = new t.Element();
  e.keys  = [10,20,30]
  e.data  = [10,20,30]
  e.nodes = [0,1,2,3]

  is_deeply(e.check(10), 0)
  is_deeply(e.check(20), 1)
  is_deeply(e.check(4) === null ? 1 : 0, 1)

  is_deeply(e.step( 5), 0)
  is_deeply(e.step(15), 1)
  is_deeply(e.step(25), 2)
  is_deeply(e.step(35), 3)
 }

if (testing)                                                                    // Tests for Tree - merge
 {const t = new Tree(4), p = new t.Element(), c = new t.Element();
  c.keys  = [12]
  c.data  = [120]
  c.nodes = [11,13]
  p.keys  = [10, 20]
  p.data  = [100, 200]
  p.nodes = [5, c, 25]

  p.merge(c)

  is_deeply(p.keys,  [10,  12,  20])
  is_deeply(p.data,  [100, 120, 200])
  is_deeply(p.nodes, [5, 11, 13, 25])
 }

if (testing)                                                                    // Tests for Tree - merge leaf - in middle
 {const t = new Tree(4), p = new t.Element();
  p.keys  = [10, 20]
  p.data  = [100, 200]

  p.mergeLeaf(15, 150)

  is_deeply(p.keys,  [10,  15,  20])
  is_deeply(p.data,  [100, 150, 200])
  is_deeply(p.nodes.length, 0)
 }

if (testing)                                                                    // Tests for Tree - merge leaf - at end
 {const t = new Tree(4), p = new t.Element();
  p.keys  = [10, 20]
  p.data  = [100, 200]

  p.mergeLeaf(30, 300)

  is_deeply(p.keys,  [10,  20,  30 ])
  is_deeply(p.data,  [100, 200, 300])
  is_deeply(p.nodes.length, 0)
 }

if (testing)                                                                    // Tests for Tree - put
 {const t = new Tree(4), N = 16

  function dd(number)
   {return number < 10 ? '0'+number : number
   }

  for(let i = 0; i < N; ++i)
   {t.set(dd(i), 2 * i)
    for(let j = 0; j < i; ++j)
     {assert(t.get(dd(j)) == 2 * j)
     }
    assert(t.get(dd(i+1)) === null)
   }

  is_deeply(t.keys(), range(0, N).map((x)=>dd(x)).sort())                       // Sort into character order rather than numeric order

  is_deeply(t.getFirst(), "00")
  for(let i = 0; i < N-1; ++i)                                                  // Check succeeding values
   {is_deeply(t.getNext(dd(i)), dd(i+1))
   }
  is_deeply(t.getLast(),  dd(N-1))
  assert(t.getNext(dd(N-1)) === null)
 }

if (testing) testResults()

return {dump, equal, Hash, is_deeply, LinkedList, not_deeply, range, say, stop, testResults, Tree}

}

if(process.argv[1].match(/basics\.js/)) Testing(true)                           // Testing if called directly

//module.exports = {dump, equal, Hash, is_deeply, LinkedList, not_deeply, say, stop, testResults, Tree}
module.exports = {Testing}
