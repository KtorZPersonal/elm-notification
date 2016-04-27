'use strict'

const fs = require('fs')
const path = require('path')

let buf = ""

/* Import the Index file to bundle it with the application */
buf += `require(__dirname + '/index.html')\n`


/* Import each css file */
function walk(base) {
    fs.readdirSync(__dirname + base).forEach(x => {
        if (fs.statSync(__dirname + base + x).isDirectory()) {
            return walk(base + x + "/")
        }
        if (path.extname(x) === ".sass") {
            buf += `require(__dirname + '${base + x}')\n`
        }
    })
}
walk('/../src/')


/* Start the application */
buf += `var Elm = require(__dirname + '/../src/Main.elm')\n`
buf += `var app = Elm.embed(Elm.Main, document.getElementById("main"))\n`

fs.writeFileSync(__dirname + '/app.js', buf)
