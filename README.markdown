A handy toolbelt for SQLite operations in the context of multitenant Rack applications.
It's internal for now and not really ready for public consumption.

### What it does?

Some small orchestration related to ActiveRecord and SQLite3 databases. First of all, it allows
for effortless database switching using Rack environment variables or what have you. Now,
in theory you could set up the `DATABASE_URI` envar to take care of this, but we need a few
things to happen aside from that.

### Connection pool

It also manages a connection pool, for the case that you use multiple threads. The pool is provided
by ActiveRecord itself, but we make sure, in our middleware, that the connections get checked
back in when the Rack app completes a request. This is similar to how Rails does this.

# Database backups

Another thing we support is a shorthand for the obscure SQLite3 backup API, which permits us to 
create one-file backups of the database. Using this technique ensures that the backup will not
happen in-flight during a transaction on the database, since it uses the provided SQLite3
backup page semantics.

### JIT migrations

Yet another nice thing is on-demand migrations. This won't be applicable to all possible scenarios
(if you need your table metadata to be available before you run a request, for instance), but it
worked well enough for us to consider it viable. It is also a nice solution for multi-tenant
SQLite3 apps which will upgrade themselves on the first request - since they are not expected
to have too much data.

### Dreaded timeouts

Extensive bodies of work have been written on the SQLite3 concurrency. The common consensus is
**do not use SQLite for concurrent applications**, however, it's very far removed from the truth.
The truth is that when you have concurrent reads SQLite3 will handle them just fine. When you do
have concurrent writes, however, what is much more likely (unless you are indeed running an
app that has outgrown SQLite3) is that SQLite3 timeouts prematurely because it assumes that right
at the first try, when it sees that the database is locked, it will simply throw and won't execute
the transaction. For some situations that will work, but normally you just want your app to wait
until the write lock on the database is released. And that waiting usually won't be all too long.

This is why we define a way to set a timeout.

### Usage

For now, you will need to inherit from `SQLiteWrapper` and override a number of methods, please read
the source for that. We told you it's not for public consumption, right?