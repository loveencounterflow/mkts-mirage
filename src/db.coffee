

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
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
{ assign
  jr }                    = CND
#...........................................................................................................
join_path                 = ( P... ) -> PATH.resolve PATH.join P...
boolean_as_int            = ( x ) -> if x then 1 else 0
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
xrpr2                     = ( x ) -> inspect x, { colors: yes, breakLength: 80,       maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
ICQL                      = require 'icql'
# INTERTYPE                 = require './types'
{ assign
  abspath }               = require './helpers'

#-----------------------------------------------------------------------------------------------------------
@get_icql_settings = ( db_path = null ) ->
  ### TAINT path within node_modules might differ ###
  ### TAINT extensions should conceivably be configured in `*.icql` file or similar ###
  # R.db_path   = join_path __dirname, '../../db/data.db'
  R                 = {}
  R.connector       = require 'better-sqlite3'
  R.db_path         = db_path ? abspath './db/mkts.db'
  R.icql_path       = abspath './db/mkts.icql'
  return R

#-----------------------------------------------------------------------------------------------------------
@new_db = ( settings ) ->
  db                    = ICQL.bind @get_icql_settings ( settings?.db_path ? null )
  clear_db              = settings?.clear ? false
  @load_extensions      db
  @set_pragmas          db
  #.........................................................................................................
  if clear_db
    clear_count = db.$.clear()
    info "deleted #{clear_count} objects"
  #.........................................................................................................
  @create_db_functions  db
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
  warn "skipping sqlite extensions"
  return null
  extensions_path = abspath './sqlite-for-mingkwai-ime/extensions'
  debug 'µ39982', "extensions_path", extensions_path
  db.$.load join_path extensions_path, 'spellfix.so'
  db.$.load join_path extensions_path, 'csv.so'
  db.$.load join_path extensions_path, 'regexp.so'
  db.$.load join_path extensions_path, 'series.so'
  db.$.load join_path extensions_path, 'nextchar.so'
  # db.$.load join_path extensions_path, 'stmt.so'
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@create_db_functions = ( db ) ->
  # db.$.function 'add_spellfix_confusable', ( a, b ) ->
  # db.$.function 'spellfix1_phonehash', ( x ) ->
  #   debug '23363', x
  #   return x.toUpperCase()

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
  db.$.function 'contains_word', { deterministic: true, varargs: false }, ( text, probe ) ->
    return if ( ( ' ' + text + ' ' ).indexOf ' ' + probe + ' ' ) > -1 then 1 else 0

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'get_words', { deterministic: true, varargs: false }, ( text ) ->
    ### Given a text, return a JSON array with words (whitespace-separated non-empty substrings). ###
    JSON.stringify ( word for word in text.split /\s+/ when word isnt '' )

  # #---------------------------------------------------------------------------------------------------------
  # db.$.function 'vnr_encode_textual', { deterministic: true, varargs: false }, ( vnr ) ->
  #   ( ( "#{idx}".padStart 6, '0' ) for idx in ( JSON.parse vnr ) ).join '-'

  #---------------------------------------------------------------------------------------------------------
  db.$.function 'vnr_encode', { deterministic: true, varargs: false }, ( vnr ) ->
    try
      Uint32Array.from JSON.parse vnr
    catch error
      warn "µ33211 when trying to convert #{xrpr2 vnr}"
      warn "µ33211 to a typed array, an error occurred:"
      warn "µ33211 #{error.message}"
      throw error

  # #---------------------------------------------------------------------------------------------------------
  # db.$.function 'get_nth_word', { deterministic: true, varargs: false }, ( text, nr ) ->
  #   ### NB SQLite has no string aggregation, no string splitting, and in general does not implement
  #   table-returning user-defined functions (except in C, see the `prefixes` extension). Also, you can't
  #   modify tables from within a UDF because the connection is of course busy executing the UDF.
  #   As a consequence, it is well-nigh impossible to split strings to rows in a decent manner. You could
  #   probably write a 12-liner with a recursive CTE each time you want to split a string. Unnecessary to
  #   mention that SQLite does not support putting *that* thing into a UDF (because those can't return
  #   anything except a single atomic value).

  #   **Update** Turns out the `json1` extension can help out; see the `get_words()` UDF. ###
  #   ### TAINT to be deprecated in favor of `get_words()` ###
  #   parts = text.split /\s+/
  #   return parts[ nr - 1 ] ? null

  #---------------------------------------------------------------------------------------------------------
  return null







