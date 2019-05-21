


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-PARSER/TYPES'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
jr                        = JSON.stringify
Intertype                 = ( require 'intertype' ).Intertype
intertype                 = new Intertype module.exports

#-----------------------------------------------------------------------------------------------------------
@declare 'mirage_main_row',
  tests:
    "? is a object":                          ( x ) -> @isa.object          x
    "? has key 'key'":                        ( x ) -> @has_key             x, 'key'
    "? has key 'vnr_txt'":                    ( x ) -> @has_key             x, 'vnr_txt'
    "? has key 'value'":                      ( x ) -> @has_key             x, 'value'
    "?.key is a nonempty text":               ( x ) -> @isa.nonempty_text   x.key
    "?.vnr_txt is a nonempty text":           ( x ) -> @isa.nonempty_text   x.vnr_txt
    "?.vnr_txt starts, ends with '[]'":       ( x ) -> ( x.vnr_txt.match /^\[.*\]$/ )?
    "?.vnr_txt is a JSON array of integers":  ( x ) ->
      lst = JSON.parse x.vnr_txt
      return false unless @isa.list lst
      return lst.every ( xx ) => @isa.positive_integer xx

# #-----------------------------------------------------------------------------------------------------------
# @declare 'true', ( x ) -> x is true

