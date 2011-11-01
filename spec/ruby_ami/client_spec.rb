require 'spec_helper'

module RubyAMI
  describe Client do
    let(:options) do
      {
        :server   => '127.0.0.1',
        :port     => 5038,
        :username => 'username',
        :password => 'password'
      }
    end

    subject { Client.new options }

    it { should be_stopped }

    its(:options) { should == options }

    its(:action_queue) { should be_a Queue }
    its(:action_queue) { should be_empty }

    describe 'sending actions' do
      let(:action_name) { 'Login' }
      let :headers do
        {
          'Username'  => 'username',
          'Secret'    => 'password'
        }
      end
      let(:expected_action) { Action.new action_name, headers }

      it 'should queue up actions to be sent' do
        subject.send_action action_name, headers
        subject.action_queue.pop(true).to_s.should == expected_action.to_s
      end
    end

    it "can send multiple messages from different processes and receive responses"
  end
end
