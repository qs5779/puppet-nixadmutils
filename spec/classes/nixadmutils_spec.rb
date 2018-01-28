require 'spec_helper'

describe 'nixadmutils' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_file('/opt/nixadmutils') }
      it { is_expected.to contain_file('/opt/nixadmutils/etc') }
      it { is_expected.to contain_file('/opt/nixadmutils/etc/nixadmutils.rc') }
      it { is_expected.to contain_file('/opt/nixadmutils/bin') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin') }
      it { is_expected.to contain_file('/etc/profile.d/nixadmutils.csh') }
      it { is_expected.to contain_file('/etc/profile.d/nixadmutils.sh') }
    end
  end
end
