


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
    "x.db_path is a ?nonempty text":          ( x ) -> ( not x.db_path?     ) or @isa.nonempty_text x.db_path
    "x.icql_path is a ?nonempty text":        ( x ) -> ( not x.icql_path?   ) or @isa.nonempty_text x.icql_path
    "x.default_key is a ?nonempty text":      ( x ) -> ( not x.default_key? ) or @isa.nonempty_text x.default_key

#-----------------------------------------------------------------------------------------------------------
@declare 'mirage_main_row',
  tests:
    "x is a object":                          ( x ) -> @isa.object          x
    "x has key 'key'":                        ( x ) -> @has_key             x, 'key'
    "x has key 'vnr'":                        ( x ) -> @has_key             x, 'vnr'
    "x has key 'value'":                      ( x ) -> @has_key             x, 'value'
    "x.key is a nonempty text":               ( x ) -> @isa.nonempty_text   x.key
    "x.vnr is a nonempty text":               ( x ) -> @isa.nonempty_text   x.vnr
    "x.vnr starts, ends with '[]'":           ( x ) -> ( x.vnr.match /^\[.*\]$/ )?
    "x.vnr is a JSON array of integers":      ( x ) ->
      lst = JSON.parse x.vnr
      return false unless @isa.list lst
      return lst.every ( xx ) => @isa.integer xx

# #-----------------------------------------------------------------------------------------------------------
# @declare 'true', ( x ) -> x is true

