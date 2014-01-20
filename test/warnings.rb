JRuby.runtime.warnings.disable_warnings_for_tests

def without_warnings
  begin
    old_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
