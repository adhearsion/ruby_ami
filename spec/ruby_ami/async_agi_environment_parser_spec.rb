# encoding: utf-8
require 'spec_helper'

module RubyAMI
  describe AsyncAGIEnvironmentParser do
    let :environment_string do
      "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
    end

    subject { described_class.new environment_string }

    its(:to_s) { should == environment_string }
    its(:to_s) { should_not be environment_string }

    describe 'retrieving a hash representation' do
      its(:to_hash) do
        should == {
          :agi_request      => 'async',
          :agi_channel      => 'SIP/1234-00000000',
          :agi_language     => 'en',
          :agi_type         => 'SIP',
          :agi_uniqueid     => '1320835995.0',
          :agi_version      => '1.8.4.1',
          :agi_callerid     => '5678',
          :agi_calleridname => 'Jane Smith',
          :agi_callingpres  => '0',
          :agi_callingani2  => '0',
          :agi_callington   => '0',
          :agi_callingtns   => '0',
          :agi_dnid         => '1000',
          :agi_rdnis        => 'unknown',
          :agi_context      => 'default',
          :agi_extension    => '1000',
          :agi_priority     => '1',
          :agi_enhanced     => '0.0',
          :agi_accountcode  => '',
          :agi_threadid     => '4366221312'
        }
      end

      it "should not return the same hash object every time" do
        subject.to_hash.should_not be subject.to_hash
      end
    end
  end
end
