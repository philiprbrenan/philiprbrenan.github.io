const {say, is_deeply, stop, dump, LinkedList, Hash} = require("../basics.js")

class LinkedListClass                                                           // Linked list as a class
 {constructor() {this.first = null; this.last = null;}

  push(value)                                                                   // Push a new element onto the end of the list
   {const n = new LinkedListElement(value)
    if (this.first == null)
     {this.first = this.last = n
      return
     }
    this.last.next = n; n.prev = this.last
    this.last = n
   }

  print()                                                                       // Print the list
   {for(let p = this.first; p != null; p = p.next) say(p.value)
   }
 }

class LinkedListElement                                                         // Element of a linked list
 {constructor(value)
   {this.value = value; this.next = this.prev = null;
   }
 }

if (1)                                                                          // Tests for linked list class
 {const l = new LinkedListClass()
  for(let i = 0; i < 9; ++i) l.push(i)
  is_deeply(l.first.value,      0)
  is_deeply(l.first.next.value, 1)
  is_deeply(l.last.prev.value,  7)
  is_deeply(l.last.value,       8)
 }

if (1)                                                                          // Test maps
 {const a = new Map()

  a.set("a", 1)
  a.set("b", 2)

  is_deeply(a.get("a"), 1)
  is_deeply(a.get("b"), 2)
  is_deeply(a, new Map([["a", 1], ["b", 2]]))

  function f(){}
  say(f)
 }

if (1)                                                                          // Tests for linked list function
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

if (1)                                                                          // Tests for linked list function
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
