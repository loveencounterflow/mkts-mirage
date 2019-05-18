

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
PD                        = require 'pipedreams'
{ $
  $async
  select }                = PD
{ assign
  jr }                    = CND
@_drop_extension          = ( path ) -> path[ ... path.length - ( PATH.extname path ).length ]
types                     = require './types'
#...........................................................................................................
{ isa
  validate
  declare
  size_of
  type_of }               = types
#...........................................................................................................
{ assign
  abspath
  relpath }               = require './helpers'
#...........................................................................................................
require                   './exception-handler'
TMP                       = require 'tmp-promise'


#-----------------------------------------------------------------------------------------------------------
last_of   = ( x ) -> x[ ( size_of x ) - 1 ]
@$as_line = => $ ( line, send ) => send line + '\n'

#-----------------------------------------------------------------------------------------------------------
as_sql = ( x ) ->
  validate.text x
  R = x
  R = R.replace /'/g, "''"
  return "'#{R}'"

#-----------------------------------------------------------------------------------------------------------
@$as_sql = =>
  first           = Symbol 'first'
  last            = Symbol 'last'
  is_first_record = true
  lnr             = 0
  return $ { first, last, }, ( line, send ) =>
    #.......................................................................................................
    ### TAINT consider to store SQL as `fragment`s in `mkts.icql` ###
    if line is first
      send "drop table if exists main;"
      send "create table main ( "
      send "    vlnr      json unique primary key,"
      send "    stamped   boolean default false,"
      send "    line      text );"
      send "insert into main ( vlnr, line ) values"
    #.......................................................................................................
    else if line is last
      send ";"
      send "create unique index idx_main_lnr on main ( lnr );"
    #.......................................................................................................
    else
      lnr  += +1
      comma = if is_first_record then '' else ','
      is_first_record = false
      send """#{comma}( "[#{lnr}]", #{as_sql line} )"""
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@$tee_write_sql = ( target_path_sql ) =>
  pipeline = []
  pipeline.push @$as_sql()
  pipeline.push @$as_line()
  pipeline.push PD.write_to_file target_path_sql
  return PD.$tee PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@write_sql_cache = ( settings ) -> new Promise ( resolve, reject ) =>
  validate.object settings
  S = settings
  help "#{rpr S.rel_source_path} -> #{S.rel_target_path}"
  #.........................................................................................................
  pipeline = []
  pipeline.push PD.read_from_file S.source_path
  pipeline.push PD.$split()
  pipeline.push @$tee_write_sql S.target_path_sql
  pipeline.push PD.$drain =>
    help "wrote output to #{rpr S.rel_target_path}"
    resolve()
  PD.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
_$count = ( step ) ->
  nr = 0
  return PD.$watch ( d ) =>
    nr += +1
    if ( nr %% step ) is 0
      whisper 'µ44744', nr
    return null

#-----------------------------------------------------------------------------------------------------------
@populate_db = ( settings ) -> new Promise ( resolve, reject ) =>
  validate.object settings
  S = settings
  S.db.$.read S.target_path_sql
  for row from S.db.read_lines { limit: 10, }
    info jr row
  line_count = S.db.$.first_value S.db.count_lines()
  info "MKTS document #{rpr S.rel_source_path} has #{line_count} lines"
  resolve()

#-----------------------------------------------------------------------------------------------------------
@cleanup = ( settings ) -> new Promise ( resolve, reject ) =>
  settings.remove_tmpfile()
  resolve()

#-----------------------------------------------------------------------------------------------------------
@new_settings = ( settings ) ->
  validate.true ( isa_text = isa.text settings ) or ( isa.object settings )
  settings = { source_path: settings, } if isa_text
  tmp                     = TMP.fileSync()
  R                       = {}
  R.db                    = ( require './db' ).new_db { clear: false, }
  R.testing               = settings.testing ? false
  R.tmpfile_path          = tmp.name
  R.remove_tmpfile        = tmp.removeCallback
  R.target_path_sql       = R.tmpfile_path
  R.source_path           = settings.source_path
  R.rel_source_path       = relpath R.source_path
  R.rel_target_path       = relpath R.target_path_sql
  return R


############################################################################################################
unless module.parent?
  testing = true
  L = @
  do ->
    #.......................................................................................................
    settings = L.new_settings './README.md'
    await L.write_sql_cache     settings
    await L.populate_db         settings
    await L.cleanup             settings
    delete settings.db
    debug 'µ69688', settings
    help 'ok'


