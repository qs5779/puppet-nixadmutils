require 'spec_helper'

describe 'nixadmutils' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_file('/opt/nixadmutils').with_ensure('directory') }
      it { is_expected.to contain_file('/opt/nixadmutils/etc').with_ensure('directory') }
      it { is_expected.to contain_file('/opt/nixadmutils/bin').with_ensure('directory') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin').with_ensure('directory') }
      it { is_expected.to contain_file('/opt/nixadmutils/lib').with_ensure('directory') }
      it { is_expected.to contain_file('/opt/nixadmutils/var').with_ensure('directory') }
      it { is_expected.to contain_file('/opt/nixadmutils/build').with_ensure('directory') }
      it { is_expected.to contain_file('/etc/profile.d/nixadmutils.csh').with_ensure('file') }
      it { is_expected.to contain_file('/etc/profile.d/nixadmutils.sh').with_ensure('file') }
      it { is_expected.to contain_file('/opt/nixadmutils/etc/nixadmutils.rc').with_ensure('file') }
      it { is_expected.to contain_file('/opt/nixadmutils/build/bin/gitx').with_ensure('link') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/lspuppet').with_ensure('link') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/pupenv').with_ensure('link') }
      it { is_expected.to contain_file('/opt/nixadmutils/bin/wtfo-logger').with_ensure('absent') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/pupaction').with_ensure('absent') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/pupstatus').with_ensure('absent') }
      it { is_expected.to contain_file('/opt/nixadmutils/sbin/puptrigger').with_ensure('absent') }
      it { is_expected.to contain_file('/opt/nixadmutils/bin/pkglist').with_ensure('absent') }
      it { is_expected.to contain_file('/opt/nixadmutils/bin/fw-list').with_ensure('absent') }
      it { is_expected.to contain_exec('/opt/nixadmutils/bin') }
      it { is_expected.to contain_exec('/opt/nixadmutils/build') }
      it { is_expected.to contain_exec('/opt/nixadmutils/sbin') }
      it { is_expected.to contain_exec('/opt/nixadmutils/lib') }
      it { is_expected.to contain_exec('chmod 664 /opt/nixadmutils/var/alerts.yaml') }
      it { is_expected.to contain_class('Nixadmutils::Config') }
      it { is_expected.to contain_class('Nixadmutils::Install') }
      it { is_expected.to contain_class('Nixadmutils::Params') }

      case os
      when %r{amazon}
        it { is_expected.to contain_package('python3-pip') }
        %w[packaging distro PyYAML feedparser lockfile pytz systemd-python].each do |pkg|
          it { is_expected.to contain_exec("pip3 install #{pkg}") }
        end
      when %r{archlinux}
        %w[python-pip python-pytz python-distro python-packaging python-systemd python-yaml python-feedparser python-lockfile].each do |pkg|
          it { is_expected.to contain_package(pkg) }
        end
      when %r{debian|ubuntu}
        %w[python3-pip python3-tz python3-distro python3-packaging python3-systemd python3-yaml python3-feedparser python3-lockfile].each do |pkg|
          it { is_expected.to contain_package(pkg) }
        end
      # when %r{centos|oraclelinux|redhat|scientific}
      #   if os_facts[:operatingsystemrelease].to_i < 8
      #     %w[packaging distro PyYAML feedparser lockfile pytz systemd-python].each do |pkg|
      #       it { is_expected.to contain_exec("pip3 install #{pkg}") }
      #     end
      #   else
      #     %w[packaging distro].each do |pkg|
      #       it { is_expected.to contain_exec("pip3 install #{pkg}") }
      #     end
      #     %w[python3-pip python3-tz python3-distro python3-packaging python3-systemd python3-yaml python3-feedparser python3-lockfile].each do |pkg|
      #       it { is_expected.to contain_package(pkg) }
      #     end
      #   end
      end
    end
  end
end
