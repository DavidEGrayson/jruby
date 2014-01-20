# Regression test for https://github.com/jruby/jruby/issues/1422

require 'zlib'
require 'stringio'

describe Zlib::GzipReader do
  it "reads mtime from bytes 4-7" do
    io = StringIO.new "\x1f\x8b\x08\x00\x44\x33\x22\x11\x00\xff\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    r = Zlib::GzipReader.new(io)
    p r.method(:mtime)
    expect(r.mtime.to_i).to eq 0x11223344
  end
end

