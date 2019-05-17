
# MKTS Mirage 明快排字機　ミラージュ

The first step in converting an MKTScript document into TeX source consists in mirroring the file contents
into a SQLite database; the text will then be parsed and be 'expanded' into its target shape.

One might object that the duplication of a—potentially big—file into a DB just to read and process its
content is inefficient and slow, but in fact even huge text files are, most of the time, minuscule in
comparison to today's storage sizes.

As for performance, MKTS Mirage gets a 2.7 MB, 89,000 lines file into the database in 2.1 seconds on my
woefully underpowered netbook; I think that is rather impressive given that this actually works by wrapping
each line into a SQL `insert` statement; the entire statement is then first written to a temporary file, and
then re-read using `better-sqlite3`'s `readFile()` method—so the amount of data moved around is actually
closer to 2 or 4 times the filesize depending on how you count (IOW there's probably room for improvement
here). By contrast, doing it the old-fashioned way (as in, `time ./sqlite sample.db < main.sql`) takes a
whopping 143 seconds on the same machine, about 70 times as long (I'd have expected a *much* better
performance here and have no clue what's going on).

### To Do

* [ ] Use `sha1sum` to avoid re-loading unmodified file
* [ ] Allow consumer to configure `*.db` location, name
* [ ] Implement nested line numbers (so the expansions of line `42` can be indexed as `[42,1]`, `[42,2]`,
  `[42,2,1]` and so on).


### Inspiration

* https://github.com/loveencounterflow/intershop

<!--

create table test ( idx json );

insert into test values
( "[42,3]"    ),
( "[42,2]"    ),
( "[12]"      ),
( "[42,0]"    ),
( "[42]"      ),
( "[42,null]" ),
( "[42,10]"   ),
( "[42,1]"    ),
( "[42,11]"   );

SELECT * from test order by idx;
[12]
[42,0]
[42,10]
[42,11]
[42,1]
[42,2]
[42,3]
[42,null]
[42]
-->







