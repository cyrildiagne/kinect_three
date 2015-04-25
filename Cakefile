fs            = require 'fs-extra'
path          = require 'path'
which         = require 'which'
chokidar      = require 'chokidar'
cheerio       = require 'cheerio'
uglify        = require 'uglify-js'
jade          = require 'jade'
{spawn, exec} = require 'child_process'

green = '\x1B[0;32m'
reset = '\x1B[0m'



# -- SETTINGS --

src_path      = 'src'
bin_path      = 'bin'
build_path    = 'build'
lib_name      = 'main'

coff_path     = path.join src_path, 'scripts'
styl_path     = path.join src_path, 'stylesheets'
jade_path     = path.join src_path, 'templates'

build_file    = path.join build_path, lib_name + '.js'
out_file      = path.join bin_path, 'js', lib_name + '.js'
min_file      = path.join bin_path, 'js', lib_name + '.min.js'
libs_path     = path.join bin_path, 'js', 'libs'
css_out_path  = path.join bin_path, 'css'
apps_path     = path.join 'node_modules','.bin'



# -- UTILS --

launch = (cmd, options) ->
  cmd = path.join apps_path, cmd
  prcss = spawn cmd, options
  prcss.stdout.pipe process.stdout
  prcss.stderr.pipe process.stderr

run = (cmd, options, callback) ->
  cmd = path.join apps_path, cmd
  opts = ' ' + options.join ' '
  prcss = exec cmd + opts, (error) -> 
    if error then console.log error
    else callback() if callback

watch = (path, callback) ->
  chokidar.watch path, {persistent:true, ignoreInitial:true}
  .on 'all', (e, file) -> callback file 

render = (file) ->
  console.log 'rendering.. '
  name = path.basename(file).split('.')[0]
  try
    libs = fs.readdirSync(libs_path).filter (file) -> file != '.DS_Store'
    html = jade.compileFile file, pretty : true
    locals = 
      libs : libs.map (file) -> path.join('js', 'libs', file)
    fs.writeFile path.join(bin_path, name+'.html'), html(locals)
  catch e
    console.log e
  log_done()

compile = (callback) ->
  console.log 'compiling..'
  fs.ensureDirSync build_path
  run 'coffee', ['-c', '-b', '-o', build_path, coff_path], ->
    log_done()
    callback() if callback

link = (callback) ->
  console.log 'linking..'
  fs.ensureDirSync bin_path
  run 'browserify', ['-e', build_file, '-o', out_file], ->
    log_done()
    callback() if callback

log_done = -> console.log green + 'done.' + reset



# -- TASKS --

task 'dev', 'start dev env', ->
  launch 'stylus', ['-u', 'nib', '-w', styl_path, '-o', css_out_path]
  watch jade_path, render
  watch coff_path, -> compile link
  compile link
  launch 'http-server', [bin_path, '-s']

task 'clean', 'clean builds', ->
  fs.removeSync build_path

task 'build',  'build lib', -> compile link

task 'test', 'run tests', ->
  launch 'mocha', ['--compilers', 'coffee:coffee-script/register']