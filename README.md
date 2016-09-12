# pil-mithril-todo

## Example multi-user todo application using PicoLisp and mithril.js

Tested on linux and windows (https://github.com/joebo/picoLisp-win-x86-64)

Dependencies: https://github.com/joebo/pil-bcrypt

Launching: 
`pil @lib/http.l @lib/xhtml.l @lib/json.l app.l bcrypt.l -main -go`

Tests: 
`mocha test.js`

## Todo
1. session timeouts
1. user creation/removal
