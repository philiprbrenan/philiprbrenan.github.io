/*------------------------------------------------------------------------------
Javascript basics
Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2022
------------------------------------------------------------------------------*/
function say()                                                                  // Say something
 {const a = []
  for(const i of arguments)
   {if (Array.isArray(i))                                                       // Array
     {for(const j of i)
       {a.push(j)
       }
     }
    else if (Object.getPrototypeOf(i) === Map.prototype)                        // Map
     {for(const j of i.keys())
       {a.push(j, "=>", i.get(j))
       }
     }
    else                                                                        // String | number
     {a.push(i)
     }
   }
   console.log(a.join(' '))
 }

function stop()                                                                  // Say something
 {if (typeof(document) === "undefined") say(...arguments)
  else
   {alert(Array.from(arguments).join(' '))
    debugger
   }
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
     {return stop("Lengths do not match: ", got.length, "versus", expected.length)
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

  stop("Cannot compare these two types");
 }

if (typeof(document) === "undefined")                                           // Tests
 {say("a", "b", "c");
  const o = new Map([['a', 11], ['b', 22]])
  const p = new Map([['a', 11], ['b', 33]])
  say(o)
  is_deeply(o, p)
  is_deeply([1,2], [1,3])
  is_deeply([1,2], [1,2])
  is_deeply([1,2], [1,3])
 }


module.exports = { say, stop, is_deeply }
