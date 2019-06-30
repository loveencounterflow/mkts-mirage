

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-MIRAGE/MAIN'
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
{ assign
  jr }                    = CND
{ cwd_abspath
  cwd_relpath
  here_abspath
  _drop_extension
  project_abspath }       = require './helpers'
@types                    = require './types'
#...........................................................................................................
{ isa
  validate
  declare
  size_of
  last_of
  type_of }               = @types
#...........................................................................................................
require                   './exception-handler'

#-----------------------------------------------------------------------------------------------------------
@_readable_stream_from_text = ( text ) ->
  ### thx to https://stackoverflow.com/a/22085851/7568091 ###
  R = new ( require 'stream' ).Readable()
  R._read = () => {} # redundant?
  R.push text
  R.push null
  return R

#-----------------------------------------------------------------------------------------------------------
@compile_sql = ( settings ) -> new Promise ( resolve, reject ) =>
  READLINE        = require 'readline'
  S               = settings
  #.........................................................................................................
  default_dest    = S.default_dest
  default_key     = S.default_key
  default_realm   = S.default_realm
  path            = S.file_path ? '<text>'
  #.........................................................................................................
  if isa.text S.file_path then  input = FS.createReadStream         S.file_path
  else                          input = @_readable_stream_from_text S.text
  ### NOTE use crlfDelay option to recognize all instances of CRLF as a single line break ###
  reader          = READLINE.createInterface { input, crlfDelay: Infinity, }
  preamble        = []
  data            = []
  lnr             = 0
  preamble.push S.db.create_table_main_first { path, default_dest, default_key, default_realm, }
  #.........................................................................................................
  for await text from reader
    lnr++
    data[ last_idx ] += ',' if ( last_idx = data.length - 1 ) > -1
    vnr               = [ lnr, ]
    data.push ( S.db.create_table_main_middle { vnr, text, } )
  if ( last_idx = data.length - 1 ) > -1
    data[ last_idx ] = data[ last_idx ].replace /,$/g, ''
  #.........................................................................................................
  resolve [ preamble..., data..., ';', ].join '\n'
  return null

#-----------------------------------------------------------------------------------------------------------
@populate_db = ( me, sql ) -> new Promise ( resolve, reject ) =>
  validate.object me
  me.db.$.execute sql
  resolve { line_count: me.db.$.first_value me.db.count_lines(), }

#-----------------------------------------------------------------------------------------------------------
@create = ( settings ) -> new Promise ( resolve, reject ) =>
  validate.mirage_create_settings settings
  me                      = {}
  me.db                   = ( require './db' ).new_db settings
  me.dbr                  = me.db
  me.dbw                  = ( require './db' ).new_db settings
  if settings.file_path?
    me.text                 = null
    me.file_path            = cwd_abspath settings.file_path
    me.rel_file_path        = cwd_relpath me.file_path
  else
    me.text                 = settings.text
    me.file_path            = null
    me.rel_file_path        = null
  me.default_dest         = settings.default_dest   ? 'main'
  me.default_key          = settings.default_key    ? '^line'
  me.default_realm        = settings.default_realm  ? 'input'
  sql                     = await MIRAGE.compile_sql me
  { line_count, }         = await @populate_db me, sql
  me.line_count           = line_count
  resolve me


############################################################################################################
unless module.parent?
  MIRAGE  = @
  do ->
    #.......................................................................................................
    settings =
      # file_path:  './README.md'
      # file_path:  __filename
      file_path:  '/usr/share/dict/italian'
      # text:       """
      #   helo world!
      #   some literal text
      #   """
      # file_path:  './db/demo.txt'
      db_path:    './db/mkts.db'
      icql_path:  './db/mkts.icql'
    t0      = Date.now()
    mirage  = await MIRAGE.create settings
    t1      = Date.now()
    dts     = ( ( t1 - t0 ) / 1000 ).toFixed 3
    help 'µ77787', "read #{mirage.line_count} lines in #{dts} s"
    count = 0
    for row from mirage.db.read_lines()
      count++
      break if count > 5
      delete row.vnr_blob
      info 'µ33211', jr row
    help 'ok'


