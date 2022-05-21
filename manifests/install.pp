# nixadmutils::install
#
# Installs nixadmutils toolset
#
# @summary Installs nixadmutils toolset
#
# @example
#   class { 'nixadmutils::install':
#     ensure            => $ensure,
#     install_directory => $wheel,
#     wheel             => $wheel,
#   }
#
# @param ensure
#   Specifies whether to install or remove files/directories. Default present
# @param install_dir
#   Specifies the installation directory. Default /opt/nixadmutils
# @param wheel
#   Specifies the super user group name. Default wheel
# @param journal
#   Specifies whether to install libraries required for journal logging. Default true
#
class nixadmutils::install (
  Enum['present', 'absent'] $ensure,
  Stdlib::Absolutepath      $install_dir,
  String                    $wheel,
  Boolean                   $journal
) {

  if $ensure == 'present' {

    if $journal {
      $jnlpkgs = lookup('nixadmutils::journal_packages', Array[String], first, [])
      $jnlpips = lookup('nixadmutils::journal_pips', Array[String], first, [])
    }
    else {
      $jnlpkgs = $jnlpips = []
    }

    $packages = lookup('nixadmutils::required_packages', Array[String], first, [])
    $pip_package = lookup('nixadmutils::pip_package', String)

    ensure_packages($packages + $pip_package + $jnlpkgs, { ensure => present })

    $pips = $jnlpips + lookup('nixadmutils::required_pips', Array[String], first, [])

    unless empty($pips) {
      # I had no luck with the on pip provider I tried 'yuav-pip'
      # and no patience to fix it. So I am using an exec
      $pip = lookup('nixadmutils::pip_command', String)
      $pips.each | String $pkg | {
        exec {"${pip} install ${pkg}":
          path    => ['/usr/local/bin', '/usr/bin', '/bin'],
          unless  => "${pip} show ${pkg} > /dev/null",
          require => Package[$pip_package]
        }
      }
    }

    $file_ensure = file

    file { $install_dir:
      ensure => directory,
      mode   => '0755',
    }

    file { "${install_dir}/etc":
      ensure  => 'directory',
      mode    => '0755',
      owner   => 'root',
      group   => $facts['wtfo_wheel'],
      require => File[$install_dir],
    }

    $var_dir = "${install_dir}/var"
    file { $var_dir:
      ensure  => 'directory',
      mode    => '0775',
      owner   => $facts['wtfo_butler'],
      group   => $facts['wtfo_wheel'],
      require => File[$install_dir],
    }

    $alerts = "${var_dir}/alerts.yaml"
    exec {"chmod 664 ${alerts}":
      path   => ['/usr/bin', '/bin'],
      onlyif => "[ -f ${alerts} ] && [ \"$(stat -c %a ${alerts})\" != '664' ]",
    }

    file {"${install_dir}/lib/python":
      ensure  => absent,
      recurse => true,
      force   => true,
    }

    $script_directories = ['bin', 'sbin', 'build', 'lib']

    $script_directories.each | String $dn | {

      $target = "${install_dir}/${dn}"

      case $dn {
        'sbin': {
          $group = $wheel
          $mode = '0754'
        }
        'lib': {
          $group = 'root'
          $mode = '0644'
        }
        default: {
          $group = 'root'
          $mode = '0755'
        }
      }

      file { $target:
        ensure  => 'directory',
        recurse => true,
        group   => $group,
        mode    => undef,
        source  => "puppet:///modules/nixadmutils/${dn}",
        require => File[$install_dir],
        notify  => Exec[$target],
      }

      exec { $target:
        path        => '/usr/bin:/bin',
        command     => "chmod 755 ${target} ; find ${target} -type f -exec chmod ${mode} {} \\;",
        user        => 'root',
        refreshonly => true,
      }
    }

    $sbin = "${install_dir}/sbin"
    $bin = "${install_dir}/bin"

    $links = {
      "${sbin}/lspuppet" => 'puppet-ls',
      "${install_dir}/build/bin/gitx" => 'gitnox',
    }

    $links.each | String $l, String $t | {
      file { $l:
        ensure => 'link',
        target => $t,
      }
    }

    $absents = [
      "${sbin}/pupstatus",
      "${sbin}/puptrigger",
      "${sbin}/pupaction",
      "${sbin}/pupflag",
      "${sbin}/pupcfg",
      "${sbin}/pupenv",
      "${bin}/fw-list",
      "${bin}/pkglist",
      "${bin}/wtfo-logger",
    ]

    $absents.each | String $a | {

      file { $a :
        ensure => 'absent',
      }
    }
  }
  else {
    # by design this module will not remove required libraries, packages, pips
    $file_ensure = $ensure

    file { $install_dir:
      ensure  => $ensure,
      recurse => true,
      force   => true,
    }
  }

  $params = { 'install_dir' => $install_dir }
  $templates = { 'rkcheck' => 'sbin', 'rkwarnings' => 'sbin' }
  $templates.each | String $base, String $relpath | {

    $mode = $relpath ? {
      /sbin/  => '0754',
      /lib/   => '0644',
      default => '0755'
    }

    file { "${install_dir}/${relpath}/${base}":
      ensure  => $file_ensure,
      content => epp("nixadmutils/${base}.epp", $params),
      mode    => $mode,
      group   => $wheel,
    }
  }

  ['sh', 'csh'].each | String $ext | {
    file { "/etc/profile.d/nixadmutils.${ext}":
      ensure  => $file_ensure,
      content => epp("nixadmutils/nixadmutils.${ext}.epp", $params),
      mode    => '0644',
    }
  }

}
