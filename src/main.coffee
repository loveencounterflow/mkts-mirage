

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
      send "    vnr_txt   json,"
      # send "    vnr_txt  json unique,"
      send "    stamped   boolean default false,"
      send "    key       text default '^mktscript',"
      send "    value     text );"
      send "insert into main ( vnr_txt, value ) values"
    #.......................................................................................................
    else if line is last
      send ";"
      # send "create unique index idx_main_lnr on main ( lnr );"
    #.......................................................................................................
    else
      lnr  += +1
      comma = if is_first_record then '' else ','
      is_first_record = false
      send """#{comma}( '[#{lnr}]', #{as_sql line} )"""
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@_$tee_without_filter = ( bystream ) ->
  ### Given a `bystream`, send a data down both the mainstream and the bystream. This allows e.g. to log all
  events to a file sink while continuing to process the same data in the mainline. **NB** that in
  contradistinction to `pull-tee`, you can only divert to a single by-stream with each call to `PS.$tee` ###
  return ( require 'pull-tee' ) bystream

#-----------------------------------------------------------------------------------------------------------
@$tee_compile_sql = ( target_path_sql, handler ) =>
  collector = []
  pipeline  = []
  pipeline.push @$as_sql()
  # pipeline.push @$as_line()
  pipeline.push PD.$collect { collector, }
  pipeline.push PD.$drain -> handler null, collector.join '\n'
  return PD.$tee PD.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@compile_sql = ( settings ) -> new Promise ( resolve, reject ) =>
  validate.object settings
  S = settings
  # help "µ12311-1 reading #{rpr S.file_path}"
  #.........................................................................................................
  pipeline = []
  pipeline.push PD.read_from_file S.file_path
  pipeline.push PD.$split()
  pipeline.push @$tee_compile_sql S, ( error, sql ) => resolve sql
  pipeline.push PD.$drain()
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
@populate_db = ( me, sql ) -> new Promise ( resolve, reject ) =>
  validate.object me
  me.db.$.execute sql
  resolve { line_count: me.db.$.first_value me.db.count_lines(), }

#-----------------------------------------------------------------------------------------------------------
@cleanup = ( settings ) -> new Promise ( resolve, reject ) =>
  settings.remove_tmpfile()
  resolve()

#-----------------------------------------------------------------------------------------------------------
@create = ( settings ) -> new Promise ( resolve, reject ) =>
  validate.mirage_create_settings settings
  me                      = {}
  me.db                   = ( require './db' ).new_db settings
  me.dbr                  = me.db
  me.dbw                  = ( require './db' ).new_db settings
  me.file_path            = cwd_abspath settings.file_path
  me.rel_file_path        = cwd_relpath me.file_path
  sql                     = await @compile_sql me
  { line_count, }         = await @populate_db me, sql
  resolve me


############################################################################################################
unless module.parent?
  MIRAGE  = @
  do ->
    #.......................................................................................................
    settings =
      file_path:  './README.md'
      db_path:    '/tmp/mirage.db'
      icql_path:  './db/mkts.icql'
    mirage = await MIRAGE.create settings
    # delete mirage.db
    # debug 'µ69688', mirage
    help 'ok'


