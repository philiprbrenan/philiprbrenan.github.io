/*------------------------------------------------------------------------------
Javascript basics
Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2022
------------------------------------------------------------------------------*/
function say()                                                                  // Say something
 {console.log(Array.from(arguments).join(' '))
 }

if (typeof(document) === undefined)
 {say("a", "b", "c");
 }
