require File.dirname(__FILE__) + "/../spec_helper"

EXECUTOR_TEST_VALUE = 101

describe "java.util.concurrent.Executors" do
  before do
    @executor = java.util.concurrent.Executors.newSingleThreadExecutor
  end
  
  it "accepts a class that implements Callable interface" do
    cls = Class.new do
      include java.util.concurrent.Callable

      def call
        EXECUTOR_TEST_VALUE
      end
    end
    c = cls.new
    @future = without_warnings { @executor.submit(c) }
    @future.get.should == EXECUTOR_TEST_VALUE
  end
  
  after do
    @executor.shutdown
  end
  
end
