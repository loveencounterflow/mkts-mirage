

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-MIRAGE/EXPERIMENTS/VNR2'
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
MIRAGE                    = require '../..'


#-----------------------------------------------------------------------------------------------------------
@main = ( Typedarray ) ->
  urge Typedarray
  vnrs_plain = [
    [ 10, ]
    [ 10, 1 ]
    [ 10, 1, 0 ]
    [ 10, -1, 0 ]
    [ 10, -1, -1 ]
    [ 10, -1, 1 ]
    [ 10, 2 ]
    [ 10, 0 ]
    [ 10, -1 ]
    ]
  vnrs_enc = []
  for vnr_plain in vnrs_plain
    vnrs_enc.push Typedarray.from vnr_plain
  debug 'µ00922', vnrs_plain.sort()
  debug 'µ00922', vnrs_enc.sort()


############################################################################################################
unless module.parent?
  @main Uint32Array
  @main Int32Array


