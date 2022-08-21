const {say, is_deeply, stop, dump} = require("../basics.js")
const a = new Map()

a.set("a", 1)
a.set("b", 2)

is_deeply(a.get("a"), 1)
is_deeply(a.get("b"), 2)
is_deeply(a, new Map([["a", 1], ["b", 2]]))

if (1)
 {function a(){}
  say(a)
 }

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
 {this.push = (value) =>                                                        // Push a value onto the end of the list
   {if (this.first == null) this.first = this.last = new Element(value)
    else
     {(this.last.next = new Element(value)).prev = this.last
       this.last = this.last.next
     }
   }

  this.pop = () =>                                                              // Pop the value off the end of the list
   {if (this.first == null) return null
    const p = this.last.value
    if (this.first == this.last)
     {this.first = this.last = null
     }
    else
     {this.last = this.last.prev
      this.last.next = null;
     }
    return p;
   }

  this.print = () =>                                                            // Print the list
   {for(let p = this.first; p != null; p = p.next) say(p.value)
   }

  this.string = () =>                                                           // Stringify the values in the list
   {const l = []
    for(let p = this.first; p != null; p = p.next) l.push(dump(p.value))
    return l.join(" ")
   }

  this.size = () =>                                                             // Size of the list
   {let n = 0
    for(let p = this.first; p != null; p = p.next) ++n
    return n
   }

  function Element(value)                                                       // Element of linked list
   {this.value = value; this.next  = this.prev = null
   }
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
  say(l)
 }
