# frozen_string_literal: true

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

      [
        '/etc/profile.d/nixadmutils.csh',
        '/etc/profile.d/nixadmutils.sh',
        '/opt/nixadmutils/sbin/rkcheck',
        '/opt/nixadmutils/sbin/rkwarnings',
        '/opt/nixadmutils/lib/python/mwtfalertable.py',
      ].each do |pn|
        it do
          is_expected.to contain_file(pn).with_content(%r{/opt/nixadmutils})
        end
      end

      pipcmd = 'pip3'
      # rubocop:disable Style/WordArray
      case os
      when %r{amazon}
        package_list = %w[python3-pip]
        pip_list = %w[packaging distro PyYAML feedparser lockfile pytz systemd-python]
      when %r{archlinux}
        pip_list = []
        package_list = %w[python-pip python-pytz python-distro python-packaging python-systemd python-yaml python-feedparser python-lockfile]
      when %r{debian|ubuntu}
        case os_facts[:operatingsystemrelease]
        when %r{^8}
          pip_list = %w[distro packaging lockfile]
          package_list = %w[python3-pip python3-tz python3-yaml python3-feedparser]
        when %r{^16}
          pip_list = %w[distro]
          package_list = %w[python3-pip python3-tz python3-packaging python3-yaml python3-feedparser python3-lockfile]
        else
          pip_list = []
          package_list = %w[python3-pip python3-tz python3-distro python3-packaging python3-systemd python3-yaml python3-feedparser python3-lockfile]
        end
      when %r{rocky|centos|oraclelinux|redhat|scientific}
        if os_facts[:operatingsystemrelease].to_i < 8
          package_list = %w[python3]
          pip_list = %w[feedparser packaging distro PyYAML pytz lockfile]
        else
          package_list = %w[python3-distro python3-pyyaml python3-pytz python3-systemd]
          pip_list = %w[packaging feedparser lockfile]
        end
      end
      # puts "os: #{os} operatingsystemrelease: #{os_facts[:operatingsystemrelease]}"
      # puts "packages: #{package_list}"
      # puts "pips: #{pip_list}"
      # rubocop:enable Style/WordArray
      package_list.each do |pkg|
        it { is_expected.to contain_package(pkg) }
      end
      pip_list.each do |pip|
        it { is_expected.to contain_exec("#{pipcmd} install #{pip}") }
      end
    end
  end
end
