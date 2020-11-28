# nixadmutils::install
#
# Installs nixadmutils toolset
#
# @summary Installs nixadmutils toolset
#
# @example
#   include nixadmutils::install
class nixadmutils::install {

  $packages = lookup('nixadmutils::required_packages', Array[String])
  $pip_package = lookup('nixadmutils::pip_package', String)

  ensure_packages($packages + $pip_package, { ensure => present })

  $pips = lookup('nixadmutils::required_pips', Array[String], first, [])

  unless empty($pips) {
    # I had no luck with the on pip provider I tried 'yuav-pip'
    # and no patience to fix it. So I am using an exec
    $pip = lookup('nixadmutils::pip_command', String, first, 'pip')
    $pips.each | String $pkg | {
      exec {"${pip} install ${pkg}":
        path    => ['/usr/local/bin', '/usr/bin', '/bin'],
        unless  => "${pip} show ${pkg} > /dev/null",
        require => Package[$pip_package]
      }
    }
  }

  ['sh', 'csh'].each | String $ext | {
    file { "/etc/profile.d/nixadmutils.${ext}":
      ensure => 'file',
      source => "puppet:///modules/nixadmutils/nixadmutils.${ext}",
      mode   => '0644',
    }
  }

  $naudir = $nixadmutils::nixadmutilsdir
  file { $naudir:
    ensure => 'directory',
    mode   => '0755',
  }

  file { "${naudir}/etc":
    ensure  => 'directory',
    mode    => '0755',
    owner   => 'root',
    group   => $facts['wtfo_wheel'],
    require => File[$naudir],
  }

  $var_dir = "${naudir}/var"
  file { $var_dir:
    ensure  => 'directory',
    mode    => '0775',
    owner   => $facts['wtfo_butler'],
    group   => $facts['wtfo_wheel'],
    require => File[$naudir],
  }

  $alerts = "${var_dir}/alerts.yaml"
  exec {"chmod 664 ${alerts}":
    path   => ['/usr/bin', '/bin'],
    onlyif => "[ -f ${alerts} ] && [ \"$(stat -c %a ${alerts})\" != '664' ]",
  }

  $script_directories = ['bin', 'sbin', 'build', 'lib']

  $script_directories.each | String $dn | {

    $target = "${naudir}/${dn}"

    case $dn {
      'sbin': {
        $group = $nixadmutils::wheelgroup
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
      require => File[$naudir],
      notify  => Exec[$target],
    }

    exec { $target:
      path        => '/usr/bin:/bin',
      command     => "chmod 755 ${target} ; find ${target} -type f -exec chmod ${mode} {} \\;",
      user        => 'root',
      refreshonly => true,
    }
  }

  $sbin = "${naudir}/sbin"
  $bin = "${naudir}/bin"

  $links = {
    "${sbin}/lspuppet" => 'puppet-ls',
    "${sbin}/pupenv" => 'pupcfg',
    "${bin}/wtfo-logger" => 'wtflogger',
    "${naudir}/build/bin/gitx" => 'gitnox',
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
    "${naudir}/bin/fw-list",
    "${naudir}/bin/pkglist",
    '/usr/local/sbin/pacwrap',
  ]

  $absents.each | String $a | {

    file { $a :
      ensure => 'absent',
    }
  }

}
