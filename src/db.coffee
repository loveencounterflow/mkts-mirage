

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-MIRAGE/DB'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
# FS                        = require 'fs'
{ assign
  jr }                    = CND
{ cwd_abspath
  cwd_relpath
  here_abspath
  _drop_extension
  project_abspath }       = require './helpers'
#...........................................................................................................
join_path                 = ( P... ) -> PATH.resolve PATH.join P...
boolean_as_int            = ( x ) -> if x then 1 else 0
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
xrpr2                     = ( x ) -> inspect x, { colors: yes, breakLength: 80,       maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
ICQL                      = require 'icql'
project_abspath           = ( P... ) -> here_abspath __dirname, '..', P...
#...........................................................................................................
types                     = require './types'
{ isa
  validate
  cast
  declare
  size_of
  last_of
  type_of }               = types


#-----------------------------------------------------------------------------------------------------------
@_get_icql_settings = ( settings ) ->
  ### TAINT path within node_modules might differ ###
  ### TAINT extensions should conceivably be configured in `*.icql` file or similar ###
  # R.db_path   = join_path __dirname, '../../db/data.db'
  defaults          =
    db_path:          project_abspath './db/mkts.db'
    icql_path:        project_abspath './db/mkts.icql'
    clear:            false
  R                 = assign {}, defaults, settings
  R.db_path         = cwd_abspath R.db_path
  R.icql_path       = cwd_abspath R.icql_path
  return R

#-----------------------------------------------------------------------------------------------------------
@new_db = ( settings ) ->
  settings              = @_get_icql_settings settings
  db                    = ICQL.bind settings
  @load_extensions      db
  @set_pragmas          db
  #.........................................................................................................
  ### TAINT consider to move clearing DB to ICQL ###
  if settings.clear
    clear_count = db.$.clear()
    # info "µ33211 deleted #{clear_count} objects"
  #.........................................................................................................
  @create_udfs  db
  @create_api   db
  #.........................................................................................................
  return db

#-----------------------------------------------------------------------------------------------------------
@set_pragmas = ( db ) ->
  db.$.pragma 'foreign_keys = on'
  db.$.pragma 'synchronous = off' ### see https://sqlite.org/pragma.html#pragma_synchronous ###
  db.$.pragma 'journal_mode = WAL' ### see https://github.com/JoshuaWise/better-sqlite3/issues/125 ###
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@load_extensions = ( db ) ->
  return null
  # extensions_path = project_abspath './sqlite-for-mingkwai-ime/extensions'
  # debug 'µ39982', "extensions_path", extensions_path
  # db.$.load join_path extensions_path, 'spellfix.so'
  # db.$.load join_path extensions_path, 'csv.so'
  # db.$.load join_path extensions_path, 'regexp.so'
  # db.$.load join_path extensions_path, 'series.so'
  # db.$.load join_path extensions_path, 'nextchar.so'
  # # db.$.load join_path extensions_path, 'stmt.so'
  # #.........................................................................................................
  # return null

#-----------------------------------------------------------------------------------------------------------
@create_udfs = ( db ) ->

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'echo', { deterministic: false, varargs: true }, ( P... ) ->
    ### Output text to command line. ###
    ### TAINT consider to use logging method to output to app console. ###
    urge ( CND.grey 'DB' ), P...
    return null

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'e', { deterministic: false, varargs: false }, ( x ) ->
    ### Output text to command line, but returns single input value so can be used within an expression. ###
    urge ( CND.grey 'DB' ), rpr x
    return x

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'e', { deterministic: false, varargs: false }, ( mark, x ) ->
    ### Output text to command line, but returns single input value so can be used within an expression. ###
    urge ( CND.grey "DB #{mark}" ), rpr x
    return x

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'json_as_hollerith', { deterministic: false, varargs: false }, ( x ) ->
    return db.$.as_hollerith JSON.parse x

  #---------------------------------------------------------------------------------------------------------
  return null

#-----------------------------------------------------------------------------------------------------------
@create_api = ( db ) ->
  db.cast_row = ( row ) ->
    validate.mirage_main_row row
    R           = assign {}, row
    R.vnr_blob  = db.$.as_hollerith R.vnr
    R.vnr       = jr R.vnr
    R.stamped   = cast.boolean 'number', R.stamped
    return R
  #.........................................................................................................
  db.insert = ( row ) -> db._insert db.cast_row row
  db.update = ( row ) -> db._update db.cast_row row
  return null






