# sprout is a heavy dependency because of inquirer, and this file is
# loaded upfront, so we awkwardly defer deps from loading until a function
# is actually called. This shaves off about 400ms of load time when using
# anything else in roots other than templates (of course).

fs = require 'fs'
_             = require 'lodash'
W             = require 'when'
sprout        = require 'sprout'
global_config = require '../global_config'

# TODO: prepend all templates with "roots-"
exports.add = (args) ->
  sprout.add(args)

exports.remove = (args) ->
  sprout.remove(args)

exports.list = (args) ->
  sprout.list(args)

exports.default = (name) ->
  if not name then return W.reject('please provide a template name')
  if not _.contains(sprout.list(), name) then return W.reject("you do not have this template installed\n=> try `roots tpl add #{name} <url>`")

  config = global_config()
  config.set('default_template', name)

  W.resolve("default template set to #{name}")

# undocumented. resets your config file if needed
exports.reset = (override) ->
  deferred = W.defer()

  if not override
    process.stdout.write 'are you sure? (y/n) '.yellow
    process.stdin.resume()
    process.stdin.setEncoding('utf8')
    process.stdin.on 'data', (txt) ->
      process.stdin.pause()
      txt = txt.trim()
      if txt == 'y' or txt == 'Y' then return remove_roots_config(deferred)
      deferred.reject('reset cancelled')
  else
    remove_roots_config(deferred)

  return deferred.promise

remove_roots_config = (deferred) ->
  tasks = []
  tasks.push(sprout.remove(tpl)) for tpl in _.without(sprout.list(), 'roots-base')

  W.all(tasks)
    .then(-> fs.unlinkSync(global_config().path))
    .yield('config and templates reset')
    .done(deferred.resolve, deferred.reject)

