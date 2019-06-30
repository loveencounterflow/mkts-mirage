
# MKTS Mirage 明快排字機　ミラージュ

The first step in converting an MKTScript document into TeX source consists in mirroring the file contents
into a SQLite database; the text will then be parsed and be 'expanded' into its target shape.

One might object that the duplication of a—potentially big—file into a DB just to read and process its
content is inefficient and slow, but in fact even huge text files are, most of the time, minuscule in
comparison to today's storage sizes.

As for performance, MKTS Mirage gets a 2.7 MB, 89,000 lines file into the database in 2.1 seconds on my
woefully underpowered netbook; I think that is rather impressive given that this actually works by wrapping
each line into a SQL `insert` statement; the entire statement is then fed to `better-sqlite3`'s `exec()`
method. By contrast, doing it the old-fashioned way (as in, `time ./sqlite sample.db < data.sql`) takes a
whopping 143 seconds on the same machine, about 70 times as long (I'd have expected a *much* better
performance here and have no clue what's going on).

### To Do

* [ ] Use `sha1sum` to avoid re-loading unmodified file
* [X] Allow consumer to configure `*.db` location, name
* [X] Implement nested line numbers (so the expansions of line `42` can be indexed as `[42,1]`, `[42,2]`,
  `[42,2,1]` and so on).


### Inspiration

* https://github.com/loveencounterflow/intershop

