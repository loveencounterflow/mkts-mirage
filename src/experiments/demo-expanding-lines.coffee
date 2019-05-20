

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
MIRAGE                    = require '../..'


#-----------------------------------------------------------------------------------------------------------
@new_level = ( me, vlnr ) ->
  ### Given a `mirage` instance and a vectorial line number `vlnr`, return a copy of `vlnr`, call it
  `vlnr0`, which has an index of `0` appended, thus representing the pre-first `vlnr` for a level of lines
  derived from the one that the original `vlnr` pointed to. Call `advance mirage, vlnr0` to obtain the
  vectorial line number of the first line of the new level. ###
  validate.nonempty_list vlnr
  R = assign [], vlnr
  R.push 0
  return R

#-----------------------------------------------------------------------------------------------------------
@advance = ( me, vlnr ) ->
  ### Given a `mirage` instance and a vectorial line number `vlnr`, return a copy of `vlnr`, call it
  `vlnr0`, which has its last index incremented by `1`, thus representing the vectorial line number of the
  next line in the same level that is derived from the same line as its predecessor. ###
  validate.nonempty_list vlnr
  R                     = assign [], vlnr
  R[ vlnr.length - 1 ] += +1
  return R

#-----------------------------------------------------------------------------------------------------------
@$split_words = ( S ) -> $ ( d, send ) =>
  return send d unless select d, '^mktscript'
  { text, vlnr: prv_vlnr, } = d.value
  nxt_vlnr = @new_level S.mirage, prv_vlnr
    # unless isa.blank_text row.value
  for word in text.split /\s+/
    continue if word is ''
    nxt_vlnr = @advance S.mirage, nxt_vlnr
    send PD.new_event '^word', { text: word, vlnr: nxt_vlnr, }
  send stamp d

#-----------------------------------------------------------------------------------------------------------
@feed_source = ( S, source, limit = Infinity ) ->
  dbr = S.mirage.db
  nr  = 0
  for row from dbr.read_unstamped_lines()
    nr   += +1
    break if nr > limit
    ### TAINT how to convert vlnr in ICQL? ###
    vlnr_txt  = row.vlnr
    vlnr      = JSON.parse row.vlnr
    source.send PD.new_event row.key, { text: row.value, vlnr, vlnr_txt, rowid: row.rowid, }
  source.end()
  return null

#-----------------------------------------------------------------------------------------------------------
@$feed_db = ( S ) ->
  ### TAINT stopgap measure; should be implemented in ICQL ###
  db2 = ( MIRAGE.new_settings S.mirage ).db
  return $watch ( d ) =>
    return null unless d.stamped
    ### TAINT how to convert vlnr in ICQL? ###
    db2.stamp_line { vlnr: d.value.vlnr_txt, }
    return null

#-----------------------------------------------------------------------------------------------------------
@_$show = ( S ) -> $watch ( d ) =>
  if d.stamped then color = CND.grey
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
      key   = row.key.padEnd  12
      vlnr  = row.vlnr.padEnd 12
      info color "#{vlnr} #{( if row.stamped then 'S' else ' ' )} #{key} #{rpr row.value[ .. 40 ]}"
      break if ( JSON.parse row.vlnr )[ 0 ] > 20
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
  limit     = 12
  #.........................................................................................................
  pipeline  = []
  pipeline.push source
  pipeline.push @$split_words S
  pipeline.push @$feed_db     S
  pipeline.push @_$show()
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


