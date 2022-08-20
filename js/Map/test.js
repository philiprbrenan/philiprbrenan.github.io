const {say, is_deeply, stop} = require("../basics.js")
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
 {l = this
  l.push  = (value) =>
   {const e = new Element(value)
    if (l.first == null)
     {l.first = l.last = e;
      return
     }
    l.last.next = e
    e.prev = l.last
    l.last = e
   }
  l.print = () =>                                                               // Print the list
   {for(let p = l.first; p != null; p = p.next) say(p.value)
   }
  function Element(value)                                                       // Element of linked list
   {this.value = value
    this.next  = this.prev = null
   }
 }

if (1)                                                                          // Tests for linked list function
 {const l = new LinkedList()
  for(let i = 0; i < 9; ++i) l.push(i)
  is_deeply(l.first.value,      0)
  is_deeply(l.first.next.value, 1)
  is_deeply(l.last.prev.value,  7)
  is_deeply(l.last.value,       8)
say(l)
 }
