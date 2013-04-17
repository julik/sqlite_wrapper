require 'bundler'
require 'test/unit'
Bundler.require :development

require_relative '../lib/sqlite_wrapper'

class TestWrapper < Test::Unit::TestCase
  def test_saves_app_into_ivar
    w = SQLiteWrapper.new(:some_app)
    assert_equal :some_app, w.app
  end
  
  class W < SQLiteWrapper
    def path_to_database
      File.dirname(__FILE__) + "/db.sqlite"
    end
  end
  
  def test_raises_without_database_path_override
    assert_raise(RuntimeError) do
      p = Proc.new {}
      SQLiteWrapper.new(p).call({})
    end
  end
  
  def test_call_propagates_to_app
    app_has_been_called = false
    lam = lambda do | env |
      assert_kind_of Hash, env
      assert env['database']
      app_has_been_called = true
    end
    
    w = W.new(lam)
    w.call({})
    assert app_has_been_called
  end
  
  def test_disconnects_after_request
    lam = lambda do | env |
      pool = ActiveRecord::Base.connection_pool
      assert pool.active_connection?
    end
    
    W.new(lam).call({})
    pool = ActiveRecord::Base.connection_pool
    assert !pool.active_connection?
  end
end
