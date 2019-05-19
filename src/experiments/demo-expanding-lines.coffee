

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
  validate.nonempty_list vlnr
  R = assign [], vlnr
  R.push 0
  return R

#-----------------------------------------------------------------------------------------------------------
@advance = ( me, vlnr ) ->
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
    old_vlnr  = JSON.parse row.vlnr
    break if old_vlnr[ 0 ] > 10
    next_vlnr = @new_level me, old_vlnr
    unless isa.blank_text row.value
      words     = row.value.split /\s+/
      urge "processing line #{old_vlnr} (#{words.length} words)"
      for word in words
        next_vlnr = @advance me, next_vlnr
        # debug 'µ20209', next_vlnr
        # me.db.insert_line { next_vlnr, }
    # debug 'µ10021', rpr row.vlnr
    db2.stamp_line { rowid: row.rowid, }
  #.........................................................................................................
  for row from me.db.read_lines()
    color = if row.stamped then CND.grey else CND.green
    info color "#{row.rowid} #{row.vlnr} #{( if row.stamped then 'S' else ' ' )} #{rpr row.value[ .. 20 ]}"
  #.........................................................................................................
  for row from me.db.xxx_select { rowid: 3, }
    info row
  #.........................................................................................................
  for row from me.db.get_stats()
    info row
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


