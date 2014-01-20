require 'test/unit'

require_relative "envutil"

class TestGc < Test::Unit::TestCase
  class S
    def initialize(a)
      @a = a
    end
  end

  def test_gc
    prev_stress = GC.stress
    GC.stress = false unless RUBY_ENGINE == "jruby"

    assert_nothing_raised do
      1.upto(10000) {
        tmp = [0,1,2,3,4,5,6,7,8,9]
      }
      tmp = nil
    end
    l=nil
    100000.times {
      l = S.new(l)
    }
    GC.start
    assert true   # reach here or dumps core
    l = []
    100000.times {
      l.push([l])
    }
    GC.start
    assert true   # reach here or dumps core

    GC.stress = prev_stress unless RUBY_ENGINE == "jruby"
  end

  def test_enable_disable
    # These functions (or atleast enable and disable) do nothing in JRuby.
    # They do produce warnings though.
    without_warnings do
      begin
        GC.enable
        assert_equal(false, GC.enable)
        assert_equal(false, GC.disable)
        assert_equal(true, GC.disable)
        assert_equal(true, GC.disable)
        assert_nil(GC.start)
        assert_equal(true, GC.enable)
        assert_equal(false, GC.enable)
      ensure
        GC.enable
      end
    end
  end

  def test_count
    c = GC.count
    GC.start
    assert_operator(c, :<, GC.count)
  end

  def test_stat
    res = GC.stat
    assert_equal(false, res.empty?)
    assert_kind_of(Integer, res[:count])

    arg = Hash.new
    res = GC.stat(arg)
    assert_equal(arg, res)
    assert_equal(false, res.empty?)
    assert_kind_of(Integer, res[:count])
  end

  def test_singleton_method
    prev_stress = GC.stress
    assert_nothing_raised("[ruby-dev:42832]") do
      without_warnings { GC.stress = true }
      10.times do
        obj = Object.new
        def obj.foo() end
        def obj.bar() raise "obj.foo is called, but this is obj.bar" end
        obj.foo
      end
    end
  ensure
    without_warnigns { GC.stress = prev_stress }
  end

  def test_gc_parameter
    env = {
      "RUBY_GC_MALLOC_LIMIT" => "60000000",
      "RUBY_HEAP_MIN_SLOTS" => "100000"
    }
    assert_normal_exit("exit", "[ruby-core:39777]", :child_env => env)

    env = {
      "RUBYOPT" => "",
      "RUBY_HEAP_MIN_SLOTS" => "100000"
    }
    assert_in_out_err([env, "-e", "exit"], "", [], [], "[ruby-core:39795]")
    assert_in_out_err([env, "-W0", "-e", "exit"], "", [], [], "[ruby-core:39795]")
    assert_in_out_err([env, "-W1", "-e", "exit"], "", [], [], "[ruby-core:39795]")
    assert_in_out_err([env, "-w", "-e", "exit"], "", [], /heap_min_slots=100000/, "[ruby-core:39795]")
  end

  def test_profiler_enabled
    GC::Profiler.enable
    assert_equal(true, GC::Profiler.enabled?)
    GC::Profiler.disable
    assert_equal(false, GC::Profiler.enabled?)
  ensure
    GC::Profiler.disable
  end

  def test_finalizing_main_thread
    assert_in_out_err(%w[--disable-gems], <<-EOS, ["\"finalize\""], [], "[ruby-dev:46647]")
      ObjectSpace.define_finalizer(Thread.main) { p 'finalize' }
    EOS
  end
end
