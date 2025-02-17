The example from jsondiff.com.

  $ jsondiff a.json b.json
  {
    "Aidan Gillen": {
      "aboolean": [| true, "true" |],
      "array": [ [| "Game of Thron\"es", "Game of Thrones" |], "The Wire" ],
      "boolean": [| true, false |],
      "int": [| 2, "2" |],
      "object": {
        "foo": "bar",
        "object1": [- { "new prop1": "new prop value" } -],
        "object2": [- { "new prop1": "new prop value" } -],
        "object3": [- { "new prop1": "new prop value" } -],
        "object4": [- { "new prop1": "new prop value" } -]
      },
      "otherint": [+ 4 +],
      "string": "some string"
    },
    "Alexander Skarsg?rd": [+ [ "Generation Kill", "True Blood" ] +],
    "Alexander Skarsgard": [- [ "Generation Kill", "True Blood" ] -],
    "Alice Farmer": [+ [ "The Corner", "Oz", "The Wire" ] +],
    "Amy Ryan": [|
      { "one": "In Treatment", "two": "The Wire" },
      [ "In Treatment", "The Wire" ]
    |],
    "Annie Fitzgerald": [
      [- "Big Love" -],
      [+ "True Blood" +],
      "Big Love",
      [+ "The Sopranos" +],
      [+ "Oz" +]
    ],
    "Anwan Glover": [ "Treme", "The Wire" ],
    "Clarke Peters": [- null -]
  }

  $ jsondiff -diff-only a.json b.json
  {
    "Aidan Gillen": {
      "aboolean": [| true, "true" |],
      "array": [ [| "Game of Thron\"es", "Game of Thrones" |], "The Wire" ],
      "boolean": [| true, false |],
      "int": [| 2, "2" |],
      "object": {
        "object1": [- { "new prop1": "new prop value" } -],
        "object2": [- { "new prop1": "new prop value" } -],
        "object3": [- { "new prop1": "new prop value" } -],
        "object4": [- { "new prop1": "new prop value" } -]
      },
      "otherint": [+ 4 +]
    },
    "Alexander Skarsg?rd": [+ [ "Generation Kill", "True Blood" ] +],
    "Alexander Skarsgard": [- [ "Generation Kill", "True Blood" ] -],
    "Alice Farmer": [+ [ "The Corner", "Oz", "The Wire" ] +],
    "Amy Ryan": [|
      { "one": "In Treatment", "two": "The Wire" },
      [ "In Treatment", "The Wire" ]
    |],
    "Annie Fitzgerald": [
      [- "Big Love" -],
      [+ "True Blood" +],
      "Big Love",
      [+ "The Sopranos" +],
      [+ "Oz" +]
    ],
    "Clarke Peters": [- null -]
  }

  $ jsondiff list1.json list2.json