# This is mainly a regression test for Github issue #1329:
# https://github.com/jruby/jruby/issues/1329  Unmarshaled symbol has the wrong encoding
#
# It also contains two regression tests for two related issues with UnmarshalStream:
# https://github.com/jruby/jruby/pull/1338  Fixed two off-by-one errors in unmarshalInt
# https://github.com/jruby/jruby/pull/1345  Look for encoding information in all instance variables

describe 'unmarshaled symbol' do
  let(:header) { "\x04\x08" }
  let(:ivar_indicator) { (ivars.empty? ? "" : "I") }

  shared_examples_for 'encoding specified is US-ASCII' do
    it 'with all ASCII characters has encoding US-ASCII' do
      sym = Marshal.load(header + ivar_indicator + ":\x0D" + unique_symbol_data + ivars)
      expect(sym.encoding).to eq Encoding.find("US-ASCII")
      expect(sym.to_s).to eq unique_symbol_data
    end
    
    it 'with non-ASCII characters raises an EncodingError' do
      pending
      expect { Marshal.load(header + ivar_indicator + ":\x0E" + unique_symbol_data + "\x99" + ivars) }.to raise_error EncodingError, "invalid encoding symbol"
    end
  end
  
  shared_examples_for 'encoding specified is ASCII-compatible' do |encoding_name|
    it 'with all ASCII characters actually has encoding US-ASCII' do
      pending
      sym = Marshal.load(header + ivar_indicator + ":\x0D" + unique_symbol_data + ivars)
      expect(sym.encoding).to eq Encoding.find("US-ASCII")
      expect(sym.to_s).to eq unique_symbol_data
    end
    
    it 'with non-ASCII characters has the specified encoding' do
      pending if ivars.empty?
      sym = Marshal.load(header + ivar_indicator + ":\x0F" + unique_symbol_data + "\u00B5" + ivars)
      expect(sym.encoding).to eq Encoding.find(encoding_name)
      expect(sym.to_s.valid_encoding?).to be true
      expect(sym.to_s.bytes.to_a).to eq (unique_symbol_data + "\u00B5").bytes.to_a
    end
  end
  
  shared_examples_for 'encoding specified is not ASCII-compatible' do |encoding_name|
    it 'with 7-bit data has specified encoding' do
      
      sym = Marshal.load(header + ivar_indicator + ":\x0D" + symbol_data_7bit + ivars)
      expect(sym.encoding).to eq Encoding.find(encoding_name)
      expect(sym.to_s.valid_encoding?).to be true
      expect(sym.to_s.bytes.to_a).to eq symbol_data_7bit.bytes.to_a
    end
    
    it 'with 8-bit data has the specified encoding' do
      sym = Marshal.load(header + ivar_indicator + ":\x0D" + symbol_data_8bit + ivars)
      expect(sym.encoding).to eq Encoding.find(encoding_name)
      expect(sym.to_s.valid_encoding?).to be true
      expect(sym.to_s.bytes.to_a).to eq symbol_data_8bit.bytes.to_a
    end
  end
  
  context 'with no instance variables', focus: true do
    let(:ivars) { "" }
    let(:unique_symbol_data) { '9329019b' }
    it_behaves_like 'encoding specified is ASCII-compatible', 'ASCII-8BIT'    
  end

  context 'with :encoding set to US-ASCII' do
    let(:ivars) { "\x06:\x0Dencoding\"\x0DUS-ASCII" }
    let(:unique_symbol_data) { '2a3e7e98' }
    it_behaves_like 'encoding specified is US-ASCII'
  end
  
  context 'with :encoding set to ISO-8859-1' do
    let(:ivars) { "\x06:\x0Dencoding\"\x0FISO-8859-1" }
    let(:unique_symbol_data) { '390ca2c4' }
    it_behaves_like 'encoding specified is ASCII-compatible', 'ISO-8859-1'
  end
  
  context 'with :encoding set to UTF-16' do
    let(:ivars) { "\x06:\x0Dencoding\"\x0BUTF-16" }
    let(:symbol_data_7bit) { '5f31ca72' }
    let(:symbol_data_8bit) { "5f31ca7\xAB" }
    it_behaves_like 'encoding specified is not ASCII-compatible', 'UTF-16'
  end

  context 'with :E set to false' do
    let(:ivars) { "\x06:\x06EF" }
    let(:unique_symbol_data) { 'c019339b' }
    it_behaves_like 'encoding specified is US-ASCII'
  end

  context 'with :E set to true' do
    let(:ivars) { "\x06:\x06ET" }
    let(:unique_symbol_data) { '671a3e44' }
    it_behaves_like 'encoding specified is ASCII-compatible', 'UTF-8'
  end
  
  specify 'the bare minimum symbol has encoding US-ASCII' do
    pending
    sym = Marshal.load(header + ":\x05")
    expect(sym.encoding).to eq Encoding.find("US-ASCII")
    expect(sym).to eq :''
  end
  
  context 'with multiple instance variables' do
    specify 'only the last one is used' do
      iv1 = ":\x0Dencoding\"\x0BUTF-16"
      iv2 = ":\x06ET"
    
      sym = Marshal.load(header + "I:\x0Ff5d776c7\u00B5\x07" + iv1 + iv2)
      expect(sym.encoding).to eq Encoding.find("UTF-8")

      sym = Marshal.load(header + "I:\x0F70b84e31\u00B5\x07" + iv2 + iv1)
      expect(sym.encoding).to eq Encoding.find("UTF-16")
    end
  end
  
  context 'with instance variables' do
    it 'still allows linking to the symbol and its instance variable name' do
      pending
      str = header + "[\x09" +
        ":\x0Db70062d8" +
        "I:\x0F4d66fd8d\u00B5\x06:\x06ET" +
        ";\x06" +
        ";\x07"
      result = Marshal.load(str)
      expect(result).to eq [:b70062d8, :"4d66fd8d\u00B5", :"4d66fd8d\u00B5", :E]
    end
  end
  
  specify "cannot be linked to until it is fully read" do
    pending
    expect { Marshal.load(header + "I:\x06a\x06;\x06T") }.to raise_error ArgumentError, "bad symbol"
  end
  
  context "when the input specifies an encoding" do
    it "does not respect the encoding if it is from a string object" do
      pending
      data = (header + ":\x0D15db5e70").force_encoding("UTF-16")
      sym = Marshal.load(data)
      sym.encoding.should == Encoding.find("US-ASCII")
    end
  end
  
end

describe 'unmarshaled string' do
  # Regression test for GH-1345 https://github.com/jruby/jruby/pull/1345
  it "uses the last encoding found in the instance variables" do
    sym = Marshal.load("\x04\x08I\"\x06a\x07:\x0Dencoding\"\x0DUTF-16LE:\x0Dencoding\"\x0DUTF-16BE")
    sym.encoding.should == Encoding.find("UTF-16BE")
  end
end

describe 'unmarshaled integer' do
  # Regression test for GH-1338 https://github.com/jruby/jruby/pull/1338
  it 'has three ways to specify 0 in a single byte' do
    Marshal.load("\x04\x08i\x00").should == 0
    Marshal.load("\x04\x08i\xFB").should == 0
    Marshal.load("\x04\x08i\x05").should == 0
  end
end