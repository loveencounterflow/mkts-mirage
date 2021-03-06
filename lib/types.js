(function() {
  'use strict';
  var CND, badge, debug, intertype, rpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'MKTS-MIRAGE/TYPES';

  debug = CND.get_logger('debug', badge);

  intertype = new (require('intertype')).Intertype(module.exports);

  //-----------------------------------------------------------------------------------------------------------
  this.declare('mirage_create_settings', {
    tests: {
      "x is a object": function(x) {
        return this.isa.object(x);
      },
      "x.file_path is a ?nonempty text": function(x) {
        return (x.file_path == null) || this.isa.nonempty_text(x.file_path);
      },
      "x.text is a ?text": function(x) {
        return (x.text == null) || this.isa.text(x.text);
      },
      "x.file_path? xor x.text?": function(x) {
        return ((x.text != null) || (x.file_path != null)) && !((x.text != null) && (x.file_path != null));
      },
      "x.db_path is a ?nonempty text": function(x) {
        return (x.db_path == null) || this.isa.nonempty_text(x.db_path);
      },
      "x.icql_path is a ?nonempty text": function(x) {
        return (x.icql_path == null) || this.isa.nonempty_text(x.icql_path);
      },
      "x.default_key is a ?nonempty text": function(x) {
        return (x.default_key == null) || this.isa.nonempty_text(x.default_key);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('mirage_main_row', {
    tests: {
      "x is a object": function(x) {
        return this.isa.object(x);
      },
      // "x has key 'key'":                        ( x ) -> @has_key             x, 'key'
      // "x has key 'vnr'":                        ( x ) -> @has_key             x, 'vnr'
      // "x has key 'text'":                       ( x ) -> @has_key             x, 'text'
      "x.key is a nonempty text": function(x) {
        return this.isa.nonempty_text(x.key);
      },
      "x.vnr is a list": function(x) {
        return this.isa.list(x.vnr);
      }
    }
  });

  // "x.vnr starts, ends with '[]'":           ( x ) -> ( x.vnr.match /^\[.*\]$/ )?
// "x.vnr is a JSON array of integers":      ( x ) ->
//   lst = JSON.parse x.vnr
//   return false unless @isa.list lst
//   return lst.every ( xx ) => @isa.integer xx

  // #-----------------------------------------------------------------------------------------------------------
// @declare 'true', ( x ) -> x is true

}).call(this);

//# sourceMappingURL=types.js.map