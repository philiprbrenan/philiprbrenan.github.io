const {say, is_deeply, stop, dump} = require("../basics.js")

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
