

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
  $async
  select }                = PD
{ assign
  jr }                    = CND
@_drop_extension          = ( path ) -> path[ ... path.length - ( PATH.extname path ).length ]
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
@translate_document = ( me ) ->
  validate.object me
  db2 = ( MIRAGE.new_settings me ).db
  for row from me.db.read_unstamped_lines()
    ### TAINT how to convert vlnr in ICQL? ###
    prv_vlnr  = JSON.parse row.vlnr
    break if prv_vlnr[ 0 ] > 10
    nxt_vlnr  = @new_level me, prv_vlnr
    unless isa.blank_text row.value
      words     = row.value.split /\s+/
      urge "processing line #{prv_vlnr} (#{words.length} words)"
      for word in words
        nxt_vlnr = @advance me, nxt_vlnr
        # debug 'µ20209', nxt_vlnr
        # me.db.insert_line { nxt_vlnr, }
    # debug 'µ10021', rpr row.vlnr
    db2.stamp_line { rowid: row.rowid, }
  #.........................................................................................................
  for row from me.db.read_lines()
    color = if row.stamped then CND.grey else CND.green
    key   = row.key.padEnd  12
    vlnr  = row.vlnr.padEnd 12
    info color "#{vlnr} #{( if row.stamped then 'S' else ' ' )} #{key} #{rpr row.value[ .. 40 ]}"
    break if ( JSON.parse row.vlnr )[ 0 ] > 20
  #.........................................................................................................
  for row from me.db.get_stats()
    info "#{row.key}: #{row.count}"
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


