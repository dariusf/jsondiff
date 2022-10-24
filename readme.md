```sh
opam pin git@github.com:dariusf/jsondiff.git
```

Simple and predictable top-down approach. Performs best on inputs without much nesting of arrays and objects. If arrays are of equal length, elements are matched by index, otherwise LCS without move detection is used.

```sh
dune test
dune exec ./jsondiff.exe a.json b.json
```
