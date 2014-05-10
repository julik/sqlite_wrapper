require 'bundler'
Bundler.require :development
require 'minitest/autorun'

require_relative '../lib/sqlite_wrapper'

class TestWrapper < Minitest::Test
  def test_saves_app_into_ivar
    w = SQLiteWrapper.new(:some_app)
    assert_equal :some_app, w.app
  end
  
  class W < SQLiteWrapper
    def path_to_database
      File.dirname(__FILE__) + "/db.sqlite"
    end
    
    def path_to_migrations
      # Update the database
      mig_path = File.dirname(__FILE__) + '/migrations'
    end
  end
  
  def test_raises_without_database_path_override
    assert_raises(RuntimeError) do
      p = Proc.new {}
      SQLiteWrapper.new(p).call({})
    end
  end
  
  def test_waits_until_lock_is_released
    flunk
  end
  
  def test_raises_without_migration_path_override
    assert_raises(RuntimeError) do
      SQLiteWrapper.new.migrate!
    end
  end
  
  def test_backup_within_a_request
    lam = lambda do | env |
      db = env['database']
      db.backup!
      backups = Dir.glob(File.dirname(__FILE__) + "/*_bak_*.sqlite")
      assert_equal 1, backups.length, "Should have created one backup"
    end
    
    W.new(lam).call({})
  ensure
    Dir.glob(File.dirname(__FILE__) + "/*_bak_*.sqlite").each do | f |
      File.unlink(f)
    end
  end
  
  def test_migrate_up_and_down_within_a_request
    lam = lambda do | env |
      db = env['database']
      
      db.migrate!
      ActiveRecord::Base.connection.execute('SELECT * FROM things') # should not raise
      ActiveRecord::Base.connection.execute('SELECT * FROM even_more_things') # should not raise
      
      db.migrate!(1)
      ActiveRecord::Base.connection.execute('SELECT * FROM even_more_things') # should raise
      
      throw :ended
    end
    
    assert_throws(:ended) do
      W.new(lam).call({})
    end
  end
  
  def test_migrate_within_a_request
    lam = lambda do | env |
      db = env['database']
      db.migrate!
      throw :ended
    end
    
    assert_throws :ended do
      W.new(lam).call({})
    end
  end
  
  def test_call_propagates_to_app
    app_has_been_called = false
    lam = lambda do | env |
      assert_kind_of Hash, env
      assert env['database']
      app_has_been_called = true
    end
    
    W.new(lam).call({})
    assert app_has_been_called
  end
  
  def test_disconnects_after_request
    app_has_been_called = false
    lam = lambda do | env |
      pool = ActiveRecord::Base.connection_pool
      assert pool.active_connection?
      app_has_been_called = true
    end
    
    W.new(lam).call({})
    pool = ActiveRecord::Base.connection_pool
    assert !pool.active_connection?
    assert app_has_been_called
  end
end
