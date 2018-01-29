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
    ensure => 'directory',
    mode   => '0755',
    require => File[$nixadmutils::nixadmutilsdir],
  }

  ['bin', 'sbin'].each | String $dn | {

    $group = $dn ? {
      'sbin'  => $nixadmutils::wheelgroup,
      default => 'root',
    }

    file { "${nixadmutils::nixadmutilsdir}/${dn}":
      ensure             => 'directory',
      recurse            => true,
      group              => $group,
      source_permissions => 'use_when_creating',
      source             => "puppet:///modules/nixadmutils/${dn}",
      require            => File[$nixadmutils::nixadmutilsdir],
    }
  }
}
