

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

provide_H2CNANO = ->
  #-----------------------------------------------------------------------------------------------------------
  # _invert_buffer = ( buffer, idx ) ->
  #   buffer[ i ] = ~buffer[ i ] for i in [ idx + 1 .. idx + 8 ]
  #   return buffer

  #-----------------------------------------------------------------------------------------------------------
  @encode = ( vidx ) ->
    buffer_length = vidx.length * 9
    R             = Buffer.alloc buffer_length
    bidx          = -8
    for idx in vidx
      bidx     += +8
      R[ idx ]  = 'K' # for compatibility with H2C
      R.writeDoubleBE idx, bidx + 1
    # _invert_buffer rbuffer, idx if type is tm_nnumber
    return R

  ##########################################################################################################
  return @

provide_UINT32 = ->
  #-----------------------------------------------------------------------------------------------------------
  @encode = ( vidx ) -> Uint32Array.from vidx

  ##########################################################################################################
  return @


H2CNANO = provide_H2CNANO.apply {}
UINT32  = provide_UINT32.apply {}

#-----------------------------------------------------------------------------------------------------------
@benchmark = ( settings ) ->
  H2C = require '/media/flow/kamakura/home/flow/io/hollerith-codec'
  #.........................................................................................................
  h2c_encode      = ( vidx ) -> H2C.encode      JSON.parse vidx
  h2cnano_encode  = ( vidx ) -> H2CNANO.encode  JSON.parse vidx
  uint32_encode   = ( vidx ) -> UINT32.encode   JSON.parse vidx
  vidx_encode     = ( vidx ) -> ( ( "#{idx}".padStart 6, '0' ) for idx in ( JSON.parse vidx ) ).join '-'
  #.........................................................................................................
  n       = 5e6
  probes  = []
  for nr in [ 1 .. n ]
    vidx = ( ( CND.random_integer 1, n * 2 ) for i in [ 1 .. ( CND.random_integer 1, 5 ) ] )
    probes.push JSON.stringify vidx
  # #.........................................................................................................
  # t0 = Date.now()
  # for probe in probes
  #   x = h2c_encode probe
  # t1 = Date.now()
  # debug 'µ33211-H2C', t1 - t0
  # #.........................................................................................................
  # t0 = Date.now()
  # for probe in probes
  #   x = h2cnano_encode probe
  # t1 = Date.now()
  # debug 'µ33211-H2CNANO', t1 - t0
  #.........................................................................................................
  t0 = Date.now()
  for probe in probes
    x = uint32_encode probe
  t1 = Date.now()
  debug 'µ33211-uint32', t1 - t0
  #.........................................................................................................
  t0 = Date.now()
  for probe in probes
    x = vidx_encode probe
  t1 = Date.now()
  debug 'µ33211-vidx', t1 - t0
  #.........................................................................................................
  # debug 'µ20092', probes
  return null

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
    # await @benchmark                  settings
    help 'ok'


