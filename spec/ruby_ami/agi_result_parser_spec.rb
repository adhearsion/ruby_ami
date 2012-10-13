# encoding: utf-8
require 'spec_helper'

module RubyAMI
  describe AGIResultParser do
    subject { described_class.new result_string }

    context 'with something that does not match the valid format' do
      let(:result_string) { 'foobar' }

      it 'should raise ArgumentError on creation' do
        expect { subject }.to raise_error(ArgumentError, /format/)
      end
    end

    context 'with a simple result with no data' do
      let(:result_string) { "200%20result=123%0A" }

      its(:code)      { should == 200 }
      its(:result)    { should == 123 }
      its(:data)      { should == '' }
      its(:data_hash) { should == nil }
    end

    context 'with a simple unescaped result with no data' do
      let(:result_string) { "200 result=123" }

      its(:code)      { should == 200 }
      its(:result)    { should == 123 }
      its(:data)      { should == '' }
      its(:data_hash) { should == nil }
    end

    context 'with a result and data in parens' do
      let(:result_string) { "200%20result=-123%20(timeout)%0A" }

      its(:code)      { should == 200 }
      its(:result)    { should == -123 }
      its(:data)      { should == 'timeout' }
      its(:data_hash) { should == nil }
    end

    context 'with a result and key-value data' do
      let(:result_string) { "200%20result=123%20foo=bar%0A" }

      its(:code)      { should == 200 }
      its(:result)    { should == 123 }
      its(:data)      { should == 'foo=bar' }
      its(:data_hash) { should == {'foo' => 'bar'} }
    end
  end
end
