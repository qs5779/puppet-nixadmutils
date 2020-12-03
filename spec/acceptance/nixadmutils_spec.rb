# frozen_string_literal: true

require 'spec_helper_acceptance'

# describe 'a feature', if: ['debian', 'redhat', 'ubuntu'].include?(os[:family]) do
describe 'Utilitees for Linux' do
  let(:pp) do
    <<-MANIFEST
      class { 'nixadmutils':
        journal => false
      }
    MANIFEST
  end

  it 'applies idempotently' do
    idempotent_apply(pp)
  end

  describe command('PYTHONPATH=/opt/nixadmutils/lib/python /opt/nixadmutils/bin/wtfalert') do
    its(:stderr) { should eq '' }
  end

  # describe file("/etc/feature.conf") do
  #   it { is_expected.to be_file }
  #   its(:content) { is_expected.to match %r{key = default value} }
  # end

  # describe port(777) do
  #   it { is_expected.to be_listening }
  # end
end
