

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-MIRAGE/EXPERIMENTS/VECTOR-INDEX'
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
@populate_db = ( settings ) ->
  validate.object settings
  S = settings
  # D = S.db.$.db
  # ( D.prepare "drop table if exists xxx;"               ).run()
  # ( D.prepare "create table xxx( d blob );"             ).run()
  # ( D.prepare "insert into xxx values ( ? );"           ).run [ ( Buffer.from '123' ), ]
  # debug 'µ433344', [ ( D.prepare "select * from xxx;"   ).iterate()..., ]
  S.db.vidx_create_and_populate_tables()
  names = [
    'vidx_list_unordered'
    'vidx_list_ordered_with_cached'
    'vidx_list_ordered_with_call' ]
  for name in names
    urge name
    for row from S.db[ name ]()
      info row.vidx


############################################################################################################
unless module.parent?
  testing = true
  do =>
    #.......................................................................................................
    settings = MIRAGE.new_settings '../README.md'
    await MIRAGE.write_sql_cache      settings
    await @populate_db                settings
    help 'ok'


