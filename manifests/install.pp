# nixadmutils::install
#
# Installs nixadmutils toolset
#
# @summary Installs nixadmutils toolset
#
# @example
#   include nixadmutils::install
class nixadmutils::install {

  $pvkey = $facts['python_version'] ? {
    /^2/    => 'python2',
    /^3/    => 'python3',
    default => 'dunno'
  }

  $packages = lookup('nixadmutils::required_packages', Hash[String,Array[String]])

  if $pvkey in $packages {
    ensure_packages($packages[$pvkey], { ensure => present })
  }

  $pips = lookup('nixadmutils::required_pips', Array[String], first, [])

  unless empty($pips) {
    # I had no luck with the on pip provider I tried 'yuav-pip'
    # and no patience to fix it. So I am using an exec
    $pip = lookup('nixadmutils::pip_command', String, first, 'pip')
    $pips.each | String $pkg | {
      exec {"${pip} install ${pkg}":
        path    => ['/usr/local/bin', '/usr/bin', '/bin'],
        unless  => "${pip} show ${pkg} > /dev/null",
        require => Package[$packages]
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

  file { $nixadmutils::nixadmutilsdir:
    ensure => 'directory',
    mode   => '0755',
  }

  file { "${nixadmutils::nixadmutilsdir}/etc":
    ensure  => 'directory',
    mode    => '0755',
    require => File[$nixadmutils::nixadmutilsdir],
  }

  $script_directories = ['bin', 'sbin', 'build', 'lib']

  $script_directories.each | String $dn | {

    $target = "${nixadmutils::nixadmutilsdir}/${dn}"

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
      require => File[$nixadmutils::nixadmutilsdir],
      notify  => Exec[$target],
    }

    exec { $target:
      path        => '/usr/bin:/bin',
      command     => "chmod 755 ${target} ; find ${target} -type f -exec chmod ${mode} {} \\;",
      user        => 'root',
      refreshonly => true,
    }
  }


  $sbin = "${nixadmutils::nixadmutilsdir}/sbin"

  $links = {
    "${sbin}/lspuppet" => 'puppet-ls',
    "${sbin}/pupenv" => 'pupcfg',
    "${nixadmutils::nixadmutilsdir}/build/bin/gitx" => 'gitnox',
  }

  $links.each | String $l, String $t | {
    file { $l:
      ensure => 'link',
      target => $t,
    }
  }

  $absents = [
    "${nixadmutils::nixadmutilsdir}/bin/fw-list",
    "${nixadmutils::nixadmutilsdir}/bin/pkglist",
    "${nixadmutils::nixadmutilsdir}/sbin/pacwrap",
  ]

  $absents.each | String $a | {

    file { $a :
      ensure => 'absent',
    }
  }

}
