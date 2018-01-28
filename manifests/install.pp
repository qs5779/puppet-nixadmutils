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
    file { "/etc/profile.d/nixadminutils.${ext}":
      ensure => 'file',
      source => "puppet:///modules/nixadmutils/nixadminutils.${ext}",
      mode   => '0644',
    }
  }

  file { $nixadmutils::nixadmutilsdir:
    ensure => 'directory',
    mode   => '0755',
  }

  ['etc', 'bin', 'sbin'].each | String $dn | {

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
    }
  }
}
