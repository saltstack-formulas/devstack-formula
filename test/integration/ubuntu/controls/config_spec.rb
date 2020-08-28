# frozen_string_literal: true

control 'devstack configuration' do
  title 'should match desired lines'

  describe file('/opt/stack/openrc') do
    it { should be_file }
  end
end
