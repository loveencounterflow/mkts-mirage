


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-MIRAGE/TYPES'
debug                     = CND.get_logger 'debug',     badge
intertype                 = new ( require 'intertype' ).Intertype module.exports

#-----------------------------------------------------------------------------------------------------------
@declare 'mirage_create_settings',
  tests:
    "x is a object":                          ( x ) -> @isa.object          x
    "x has key 'file_path'":                  ( x ) -> @has_key             x, 'file_path'
    # "x has key 'db_path'":                    ( x ) -> @has_key             x, 'db_path'
    # "x has key 'icql_path'":                  ( x ) -> @has_key             x, 'icql_path'
    "x.file_path is a nonempty text":         ( x ) -> @isa.nonempty_text x.file_path
    "x.db_path is a ?nonempty text":          ( x ) -> ( not x.db_path?   ) or @isa.nonempty_text x.db_path
    "x.icql_path is a ?nonempty text":        ( x ) -> ( not x.icql_path? ) or @isa.nonempty_text x.icql_path

#-----------------------------------------------------------------------------------------------------------
@declare 'mirage_main_row',
  tests:
    "x is a object":                          ( x ) -> @isa.object          x
    "x has key 'key'":                        ( x ) -> @has_key             x, 'key'
    "x has key 'vnr_txt'":                    ( x ) -> @has_key             x, 'vnr_txt'
    "x has key 'value'":                      ( x ) -> @has_key             x, 'value'
    "x.key is a nonempty text":               ( x ) -> @isa.nonempty_text   x.key
    "x.vnr_txt is a nonempty text":           ( x ) -> @isa.nonempty_text   x.vnr_txt
    "x.vnr_txt starts, ends with '[]'":       ( x ) -> ( x.vnr_txt.match /^\[.*\]$/ )?
    "x.vnr_txt is a JSON array of integers":  ( x ) ->
      lst = JSON.parse x.vnr_txt
      return false unless @isa.list lst
      return lst.every ( xx ) => @isa.positive_integer xx

# #-----------------------------------------------------------------------------------------------------------
# @declare 'true', ( x ) -> x is true

