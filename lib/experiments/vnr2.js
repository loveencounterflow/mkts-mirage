(function() {
  'use strict';
  var $, $async, CND, FS, MIRAGE, PATH, PD, abspath, assign, badge, debug, declare, echo, help, info, isa, jr, relpath, rpr, select, size_of, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'MKTS-MIRAGE/EXPERIMENTS/VNR2';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  FS = require('fs');

  PATH = require('path');

  PD = require('pipedreams');

  ({$, $async, select} = PD);

  ({assign, jr} = CND);

  this._drop_extension = function(path) {
    return path.slice(0, path.length - (PATH.extname(path)).length);
  };

  types = require('../types');

  //...........................................................................................................
  ({isa, validate, declare, size_of, type_of} = types);

  //...........................................................................................................
  ({assign, abspath, relpath} = require('../helpers'));

  //...........................................................................................................
  MIRAGE = require('../..');

  //-----------------------------------------------------------------------------------------------------------
  this.main = function(Typedarray) {
    var i, len, vnr_plain, vnrs_enc, vnrs_plain;
    urge(Typedarray);
    vnrs_plain = [[10], [10, 1], [10, 1, 0], [10, -1, 0], [10, -1, -1], [10, -1, 1], [10, 2], [10, 0], [10, -1]];
    vnrs_enc = [];
    for (i = 0, len = vnrs_plain.length; i < len; i++) {
      vnr_plain = vnrs_plain[i];
      vnrs_enc.push(Typedarray.from(vnr_plain));
    }
    debug('µ00922', vnrs_plain.sort());
    return debug('µ00922', vnrs_enc.sort());
  };

  //###########################################################################################################
  if (module.parent == null) {
    this.main(Uint32Array);
    this.main(Int32Array);
  }

}).call(this);

//# sourceMappingURL=vnr2.js.map