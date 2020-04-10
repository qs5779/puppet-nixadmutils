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
      it { is_expected.to contain_file('/opt/nixadmutils/bin/fw-list') }
      it { is_expected.to contain_file('/opt/nixadmutils/bin/pkglist') }
      it { is_expected.to contain_file('/opt/nixadmutils/build') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/findpkg') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/installpkg') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/listpkgs') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/lspuppet') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/pacwrap') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/pkgfiles') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/pkglist') }
      it { is_expected.to contain_exec('/opt/nixadmutils/bin') }
      it { is_expected.to contain_exec('/opt/nixadmutils/build') }
      it { is_expected.to contain_exec('/opt/nixadmutils/sbin') }
      it { is_expected.to contain_class('Nixadmutils::Config') }
      it { is_expected.to contain_class('Nixadmutils::Install') }
      it { is_expected.to contain_class('Nixadmutils::Params') }
    end
  end
end
