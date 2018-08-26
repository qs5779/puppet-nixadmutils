# nixadmutils::install
#
# Installs nixadmutils toolset
#
# @summary Installs nixadmutils toolset
#
# @example
#   include nixadmutils::install
class nixadmutils::install {


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

  $script_directories = ['bin', 'sbin', 'build']

  $script_directories.each | String $dn | {

    $group = $dn ? {
      'sbin'  => $nixadmutils::wheelgroup,
      default => 'root',
    }

    file { "${nixadmutils::nixadmutilsdir}/${dn}":
      ensure  => 'directory',
      recurse => true,
      group   => $group,
      mode    => undef,
      source  => "puppet:///modules/nixadmutils/${dn}",
      require => File[$nixadmutils::nixadmutilsdir],
      notify  => Exec[$name],
    }

    exec { "${nixadmutils::nixadmutilsdir}/${dn}":
      path        => '/usr/bin:/bin',
      command     => "find ${name} -type f -o -type d -exec chmod 755 {} \\;",
      user        => 'root',
      refreshonly => true,
    }
  }


  $sbin = "${nixadmutils::nixadmutilsdir}/sbin"

  $links = {
    "${sbin}/lspuppet" => 'puppet-ls'
  }

  $links.each | String $l, String $t | {
    file { $l:
      ensure => 'link',
      target => $t,
    }
  }

  $absents = [ "${nixadmutils::nixadmutilsdir}/bin/fw-list" ]

  $absents.each | String $a | {

    file { $a :
      ensure => 'absent',
    }
  }
}
