# frozen_string_literal: true

require 'spec_helper_acceptance'

logfn = '/tmp/acceptance.log'

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

  describe command("PYTHONPATH=/opt/nixadmutils/lib/python /opt/nixadmutils/bin/wtfalert -l #{logfn}") do
    its(:stderr) { is_expected.to eq '' }
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{:created} }
  end

  describe command("PYTHONPATH=/opt/nixadmutils/lib/python /opt/nixadmutils/bin/wtflogger -Ll #{logfn} 'this is a test'") do
    its(:stdout) { is_expected.to eq '' }
    its(:exit_status) { is_expected.to eq 0 }
    its(:stderr) { is_expected.to match %r{INFO: this is a test} }
  end

  describe file(logfn) do
    it { is_expected.to be_file }
    its(:content) { is_expected.to match %r{this is a test} }
  end

  describe command('PYTHONPATH=/opt/nixadmutils/lib/python /opt/nixadmutils/bin/pacwrap -h') do
    its(:stderr) { is_expected.to eq '' }
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{Actions:} }
  end
end
