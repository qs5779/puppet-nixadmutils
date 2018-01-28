# nixadmutils::config
#
# Creates/manages configuration of nixadmutils toolset
#
# @summary Creates/manages configuration of nixadmutils toolset
#
# @example
#   include nixadmutils::config
class nixadmutils::config {

  $cfgdir = "${::nixadmutils::nixadmutilsdir}/etc"

  file { "${cfgdir}/nixadmutils.rc":
    ensure  => 'file',
    mode    => '0644',
    content  => template('nixadmutils/nixadmutils.rc.erb'),
    require => File[$cfgdir],
  }
}
