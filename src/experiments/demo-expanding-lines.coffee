

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-MIRAGE/EXPERIMENTS/EXPANDING-LINES'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
FS                        = require 'fs'
PATH                      = require 'path'
PD                        = require 'pipedreams'
{ $
  $watch
  $async
  select
  stamp }                 = PD
{ assign
  jr }                    = CND
first                     = Symbol 'first'
last                      = Symbol 'last'
types                     = require '../types'
#...........................................................................................................
{ isa
  validate
  declare
  size_of
  type_of }               = types
#...........................................................................................................
{ assign
  abspath
  relpath }               = require '../helpers'
#...........................................................................................................
require                   '../exception-handler'
ICE                       = require 'icepick'
MIRAGE                    = require '../..'
do_validate               = true

###

TAINT consider to backport these flags to PipeDreams:

* [ ] `$dirty`—whether any property of a datom has beem modified;
* [ ] `$fresh`—whether a datom originated from within the stream, not from the source;
* [X] `$stamped`—whether a datom has been processed.

###

#-----------------------------------------------------------------------------------------------------------
@new_datom = ( P ... ) ->
  R           = PD.new_datom P...
  R.vnr_txt   = ( jr R.$vnr ) if ( not R.vnr_txt )? and ( R.$vnr? )
  R.$fresh    = true
  return ICE.freeze R

#-----------------------------------------------------------------------------------------------------------
@stamp = ( d ) ->
  ### NOTE we could use `icepick`'s 'copy-on-write'/structural sharing features here but that is probably
  of little effect given how small our objects are; we therefore use the much simpler 'copy-on-thaw' and
  re-freezing while enjoying the simplicity and clarity of intermittent (and contained) old-fashioned data
  mutation. ###
  R         = ICE.thaw d
  R.$stamped = true
  R.$dirty   = true
  return ICE.freeze R

#-----------------------------------------------------------------------------------------------------------
@new_vnr_level = ( S, vnr ) ->
  ### Given a `mirage` instance and a vectorial line number `vnr`, return a copy of `vnr`, call it
  `vnr0`, which has an index of `0` appended, thus representing the pre-first `vnr` for a level of lines
  derived from the one that the original `vnr` pointed to. ###
  validate.nonempty_list vnr
  R = assign [], vnr
  R.push 0
  return R

#-----------------------------------------------------------------------------------------------------------
@advance_vnr = ( S, vnr ) ->
  ### Given a `mirage` instance and a vectorial line number `vnr`, return a copy of `vnr`, call it
  `vnr0`, which has its last index incremented by `1`, thus representing the vectorial line number of the
  next line in the same level that is derived from the same line as its predecessor. ###
  validate.nonempty_list vnr
  R                    = assign [], vnr
  R[ vnr.length - 1 ] += +1
  return R

#-----------------------------------------------------------------------------------------------------------
@$split_words = ( S ) -> $ ( d, send ) =>
  return send d unless select d, '^mktscript'
  #.........................................................................................................
  send @stamp d
  text      = d.text
  prv_vnr   = d.$vnr
  nxt_vnr  = @new_vnr_level S, prv_vnr
  #.........................................................................................................
    # unless isa.blank_text row.value
  for word in text.split /\s+/
    continue if word is ''
    nxt_vnr = @advance_vnr S, nxt_vnr
    send @new_datom '^word', { text: word, $vnr: nxt_vnr, }
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@datom_from_row = ( S, row ) ->
  ### TAINT how to convert vnr in ICQL? ###
  debug 'µ22299', row
  vnr_txt     = row.vnr_txt
  $vnr        = JSON.parse vnr_txt
  R           = ICE.freeze PD.new_datom row.key, { text: row.value, $vnr, vnr_txt, }
  R.$stamped  = true if row.stamped
  debug 'µ22299', R
  debug 'µ22299', PD.new_datom '^foo', 42
  debug 'µ22299', PD.new_datom '^foo', { x: 42, }
  debug 'µ22299', isa.object { x: 42, }
  return R

#-----------------------------------------------------------------------------------------------------------
@row_from_datom = ( S, d ) ->
  ### TAINT how to convert booleans in ICQL? ###
  stamped   = if d.$stamped then 1 else 0
  R         = ICE.freeze { key: d.key, vnr_txt: d.vnr_txt, value: d.text, stamped, }
  validate.mirage_main_row R if do_validate
  return R

#-----------------------------------------------------------------------------------------------------------
@feed_source = ( S, source, limit = Infinity ) ->
  dbr = S.mirage.db
  nr  = 0
  #.........................................................................................................
  for row from dbr.read_unstamped_lines()
    nr += +1
    break if nr > limit
    source.send @datom_from_row S, row
  #.........................................................................................................
  source.end()
  return null

#-----------------------------------------------------------------------------------------------------------
@$feed_db = ( S ) ->
  ### TAINT stopgap measure; should be implemented in ICQL ###
  db2 = ( MIRAGE.new_settings S.mirage ).db
  return $watch ( d ) =>
    ### TAINT how to convert vnr in ICQL? ###
    row = @row_from_datom S, d
    try
      ### TAINT consider to use upsert instead https://www.sqlite.org/lang_UPSERT.html ###
      if      d.$fresh then db2.insert row
      else if d.$dirty then db2.update row
    catch error
      warn "µ12133 when trying to insert or update row #{jr row}"
      warn "µ12133 an error occurred:"
      warn "µ12133 #{error.message}"
      throw error
    return null

#-----------------------------------------------------------------------------------------------------------
@_$show = ( S ) -> $watch ( d ) =>
  if d.$stamped then color = CND.grey
  else
    switch d.key
      when '^word' then color = CND.gold
      else color = CND.white
  info color jr d

#-----------------------------------------------------------------------------------------------------------
@_$on_finish = ( S ) ->
  dbr = S.mirage.db
  #.........................................................................................................
  return $watch { last, }, ( d ) =>
    return null unless d is last
    #.......................................................................................................
    for row from dbr.read_lines()
      color = if row.stamped then CND.grey else CND.green
      key   = row.key.padEnd      12
      vnr   = row.vnr_txt.padEnd  12
      info color "#{vnr} #{( if row.stamped then 'S' else ' ' )} #{key} #{rpr row.value[ .. 40 ]}"
    #.......................................................................................................
    for row from dbr.get_stats()
      info "#{row.key}: #{row.count}"
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@translate_document = ( me ) -> new Promise ( resolve, reject ) =>
  ### TAINT add suitable types ###
  validate.object me
  S         = { mirage: me, }
  source    = PD.new_push_source()
  limit     = Infinity
  #.........................................................................................................
  pipeline  = []
  pipeline.push source
  pipeline.push PD.$show()
  pipeline.push @$split_words S
  pipeline.push @$feed_db     S
  # pipeline.push @_$show()
  pipeline.push @_$on_finish  S
  pipeline.push PD.$drain => resolve()
  #.........................................................................................................
  PD.pull pipeline...
  @feed_source S, source, limit
  return null


############################################################################################################
unless module.parent?
  testing = true
  do =>
    #.......................................................................................................
    mirage = MIRAGE.new_settings '../README.md'
    await MIRAGE.acquire      mirage
    await @translate_document mirage
    help 'ok'


