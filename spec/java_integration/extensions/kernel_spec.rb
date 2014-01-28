require File.dirname(__FILE__) + "/../spec_helper"

describe "Kernel Ruby extensions" do
  it "allow raising a Java exception" do
    begin
      raise java.lang.NullPointerException.new
    rescue java.lang.NullPointerException => e
      @raised_npe = true
    end
    expect(@raised_npe).to eq true
  end
end
