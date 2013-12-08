# A lean mean machine SQLite toolbelt for small apps
class SQLiteWrapper
  EXT = ".sqlite"
  BUSY_TIMEOUT = 2000
  
  attr_reader :app
  
  # Used when the wrapper is run within a Rack pipeline
  def initialize(app = nil)
    @app = app
  end
  
  # Returns the name of the current Rack environment
  # or "development" if it's undefined
  def environment_name
    ENV['RACK_ENV'] || 'development'
  end
  
  # The DB object can be used as a Rack middleware.
  # Note that even when in transacton SQLite only locks
  # when writes are actually executed - so we can in fact
  # have a transaction going and, say, run a backup
  # within it. We don't have to switch anything.
  def call(env)
    raise "@app should be set for 'Database#call` to work" unless @app
    apply_logger!(env)
    with_db_conn { @app.call(env.merge('database' => self)) }
  end
  
  # Runs the block in a transaction and with an open DB
  def in_transaction(&blk)
    with_db_conn { ActiveRecord::Base.transaction(&blk) }
  end
  
  # Runs a block with an open SQLite database and ensures the database is closed
  # at the end
  def with_db_conn
    connect!
    ActiveRecord::Base.connection_pool.with_connection do | c |
      raise_timeout_on(c)
      set_timezone!
      yield
    end
  end
  
  # Configures AR for UTC time
  def set_timezone!
    ActiveRecord::Base.default_timezone == :utc
  end
  
  # Applies the Captivity logger to AR if it's available
  def apply_logger!(rack_env)
    logger = rack_env['captivity.logger']
    ActiveRecord::Base.logger = logger if logger
  end
  
  # Connects ActiveRecord to the file
  def connect!
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: path_to_database)
  end
  
  # Return the path to the database you want to open from here
  def path_to_database
    raise "You need to override path_to_database for now to return the absolute path"
  end
  
  # Returns the UTCZ suffix for the backup file that we can make for the current
  # database
  def get_backup_suffix
    stamp = Time.now.utc.strftime("%Y%m%d_%H%M%S")
    dest_suffix = "_bak_#{stamp}"
  end
  
  # Enforce a higher timeout on the AR connection
  def raise_timeout_on(ar_conn)
    conn = ar_conn.instance_variable_get('@connection')
    conn.busy_timeout(1000)
  end
    
  # Run a SQLite backup. creates a suffixed file next to the
  # database file we backup from. This isolates the hairy
  # syntax of the Sqlite3 backup API. And it's cleaner than
  # just copying the file since this plays nice with SQLite's
  # logging semantics
  def backup!
    basename = File.basename(path_to_database, EXT)
    dest_db_filename = [basename, get_backup_suffix, EXT].join
    dest_db_path = File.join(File.dirname(path_to_database), dest_db_filename)
    
    # Note that the manual sez
    # "It cannot be used to copy data to or from in-memory databases."
    # http://www.sqlite.org/backup.html
    source_db = SQLite3::Database.new(path_to_database)
    dest_db = SQLite3::Database.new(dest_db_path)
    b = SQLite3::Backup.new(dest_db, 'main', source_db, 'main')
    loop do
      code = b.step(1)
      if code != SQLite3::Constants::ErrorCode::OK
        if code == SQLite3::Constants::ErrorCode::DONE
          return true # Success, export ended
        else
          raise "Backup returned code #{code}"
        end
      end
    end
    b.finish
    source_db.close
    dest_db.close
  end
  
  # Return the path to your migrations directory from here
  def path_to_migrations
    raise "You should override path_to_migrations"
  end
  
  # Run the migrations in transaction.
  # Path to the migrations will be fetched via path_to_migrations
  def migrate!
    in_transaction do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migrator.migrate(path_to_migrations, nil)
      end
    end
  end
end