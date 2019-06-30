(function() {
  'use strict';
  var CND, FS, MIRAGE, PATH, _$count, _drop_extension, assign, badge, cwd_abspath, cwd_relpath, debug, declare, echo, help, here_abspath, info, isa, jr, last_of, project_abspath, rpr, size_of, type_of, urge, validate, warn, whisper,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'MKTS-MIRAGE/MAIN';

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

  ({assign, jr} = CND);

  ({cwd_abspath, cwd_relpath, here_abspath, _drop_extension, project_abspath} = require('./helpers'));

  this.types = require('./types');

  //...........................................................................................................
  ({isa, validate, declare, size_of, last_of, type_of} = this.types);

  //...........................................................................................................
  require('./exception-handler');

  //-----------------------------------------------------------------------------------------------------------
  this.$as_sql = (S) => {
    var lnr;
    lnr = 0;
    return $((d, send) => {
      var comma, default_dest, default_key, default_realm, is_first, is_last, path, ref, ref1, text, vnr;
      validate.text((text = d.value));
      is_first = (ref = d.$first) != null ? ref : false;
      is_last = (ref1 = d.$last) != null ? ref1 : false;
      default_dest = S.default_dest;
      default_key = S.default_key;
      default_realm = S.default_realm;
      path = S.file_path;
      //.......................................................................................................
      if (is_first) {
        send(S.db.create_table_main_first({path, default_dest, default_key, default_realm}));
      }
      //.......................................................................................................
      lnr += +1;
      vnr = [lnr];
      comma = is_last ? '' : ',';
      send((S.db.create_table_main_middle({vnr, text})) + comma);
      //.......................................................................................................
      if (is_last) {
        return send(';');
      }
    });
    //.........................................................................................................
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.compile_sql = function(settings) {
    return new Promise(async(resolve, reject) => {
      /* NOTE use crlfDelay option to recognize all instances of CRLF as a single line break */
      var READLINE, S, data, default_dest, default_key, default_realm, input, is_last, last_idx, lnr, path, preamble, reader, text, vnr;
      READLINE = require('readline');
      S = settings;
      //.........................................................................................................
      default_dest = S.default_dest;
      default_key = S.default_key;
      default_realm = S.default_realm;
      path = S.file_path;
      //.........................................................................................................
      input = FS.createReadStream(path);
      reader = READLINE.createInterface({
        input,
        crlfDelay: 2e308
      });
      preamble = [];
      data = [];
      lnr = 0;
      is_last = true;
      preamble.push(S.db.create_table_main_first({path, default_dest, default_key, default_realm}));
//.........................................................................................................
      for await (text of reader) {
        lnr++;
        if ((last_idx = data.length - 1) > -1) {
          data[last_idx] += ',';
        }
        vnr = [lnr];
        data.push(S.db.create_table_main_middle({vnr, text}));
      }
      if ((last_idx = data.length - 1) > -1) {
        data[last_idx] = data[last_idx].replace(/,$/g, '');
      }
      //.........................................................................................................
      resolve([...preamble, ...data, ';'].join('\n'));
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  _$count = function(step) {
    var nr;
    nr = 0;
    return PD.$watch((d) => {
      nr += +1;
      if ((modulo(nr, step)) === 0) {
        whisper('µ44744', nr);
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.populate_db = function(me, sql) {
    return new Promise((resolve, reject) => {
      validate.object(me);
      me.db.$.execute(sql);
      return resolve({
        line_count: me.db.$.first_value(me.db.count_lines())
      });
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.cleanup = function(settings) {
    return new Promise((resolve, reject) => {
      settings.remove_tmpfile();
      return resolve();
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.create = function(settings) {
    return new Promise(async(resolve, reject) => {
      var line_count, me, ref, ref1, ref2, sql;
      validate.mirage_create_settings(settings);
      me = {};
      me.db = (require('./db')).new_db(settings);
      me.dbr = me.db;
      me.dbw = (require('./db')).new_db(settings);
      if (settings.file_path != null) {
        me.text = null;
        me.file_path = cwd_abspath(settings.file_path);
        me.rel_file_path = cwd_relpath(me.file_path);
      } else {
        me.text = settings.text;
        me.file_path = null;
        me.rel_file_path = null;
      }
      me.default_dest = (ref = settings.default_dest) != null ? ref : 'main';
      me.default_key = (ref1 = settings.default_key) != null ? ref1 : '^line';
      me.default_realm = (ref2 = settings.default_realm) != null ? ref2 : 'input';
      sql = (await MIRAGE.compile_sql(me));
      ({line_count} = (await this.populate_db(me, sql)));
      me.line_count = line_count;
      return resolve(me);
    });
  };

  //###########################################################################################################
  if (module.parent == null) {
    MIRAGE = this;
    (async function() {
      var count, dts, mirage, ref, row, settings, t0, t1;
      //.......................................................................................................
      settings = {
        // file_path:  './README.md'
        // file_path:  __filename
        file_path: '/usr/share/dict/italian',
        // text:       """
        //   helo world!
        //   some literal text
        //   """
        // file_path:  './db/demo.txt'
        db_path: './db/mkts.db',
        icql_path: './db/mkts.icql'
      };
      t0 = Date.now();
      mirage = (await MIRAGE.create(settings));
      t1 = Date.now();
      dts = ((t1 - t0) / 1000).toFixed(3);
      help('µ77787', `read ${mirage.line_count} lines in ${dts} s`);
      count = 0;
      ref = mirage.db.read_lines();
      for (row of ref) {
        count++;
        if (count > 5) {
          break;
        }
        delete row.vnr_blob;
        info('µ33211', jr(row));
      }
      return help('ok');
    })();
  }

}).call(this);
