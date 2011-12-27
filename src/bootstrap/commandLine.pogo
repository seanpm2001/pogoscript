fs = require 'fs'
preparser = require './preparser'
ms = require '../lib/memorystream'
parse = require './parser'
uglify = require 'uglify-js'
argv = require 'optimist': argv
errors = require './codeGenerator/errors'

preparse = preparser: create file parser!

generate code @term =
  memory stream = new (ms: MemoryStream)
  term: generate java script (memory stream)
  memory stream: to string?

beautify @code =
  ast = uglify: parser: parse @code
  uglify: uglify: gen_code @ast, beautify

exports: compile file @filename =
  js = generate java script from pogo file @filename
  beautiful js = beautify @js
  js filename = filename: replace (new (RegExp '\.pogo$')) '.js'
  fs: write file sync (js filename) (beautiful js)

exports: run file @filename =
  js = generate java script from pogo file @filename
  
  module: filename = fs: realpath sync @filename
  process: argv: 1 = module: filename
  module: _compile @js @filename

generate java script from pogo file @filename =
  contents = fs: read file sync @filename 'utf-8'
  p = preparse @contents
  term = parse @p
  
  if (errors: has errors?)
    errors: print errors (index for file @filename with source @contents)
    process: exit 1
  else
    generate code @term

index for file @file with source @source =
  object =>
    :lines in range @range =
      lines = source: split (new (RegExp '\n'))
      lines: slice ((range:from) - 1) (range:to)

    :print lines in range @range =
      for each ?line in (:lines in range @range)
          process:stderr:write (line + '\n')

    :print location @location =
      process:stderr:write (((filename + ':') + (location: first line)) + '\n')
      :print lines in range #{from (location: first line), to (location: last line)}
      process:stderr:write (((duplicate string ' ' (location: first column) times) + (duplicate string '^' ((location: last column) - (location:first column)) times)) + '\n')

duplicate string @s @n times =
    strings = []
    for {i = 0} {i < n} {i = i + 1}
      strings: push @s

    strings: join ''

if (argv: c)
  for each ?filename in (argv:_)
    compile file @filename
else
  run file (argv:_:0)
