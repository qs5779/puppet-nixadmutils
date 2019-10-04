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

    $target = "${nixadmutils::nixadmutilsdir}/${dn}"

    case $dn {
      'sbin': {
        $group = $nixadmutils::wheelgroup
        $mode = '0754'

        $pacwrap_links = ['findpkg', 'installpkg', 'pkglist', 'listpkgs' ]

        $pacwrap_links.each |$lnk| {
          file {"${target}/${lnk}":
            ensure  => link,
            target  => 'pacwrap',
            require => File[$target],
          }
        }
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
    "${sbin}/lspuppet" => 'puppet-ls'
  }

  $links.each | String $l, String $t | {
    file { $l:
      ensure => 'link',
      target => $t,
    }
  }

  $absents = [
    "${nixadmutils::nixadmutilsdir}/bin/fw-list"
    "${nixadmutils::nixadmutilsdir}/bin/pgklist"
  ]

  $absents.each | String $a | {

    file { $a :
      ensure => 'absent',
    }
  }

}
