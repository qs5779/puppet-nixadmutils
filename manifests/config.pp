# nixadmutils::config
#
# Creates/manages configuration of nixadmutils toolset
#
# @summary Creates/manages configuration of nixadmutils toolset
#
# @example
#   class { 'nixadmutils::config':
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
class nixadmutils::config (
  Enum['present', 'absent'] $ensure,
  Stdlib::Absolutepath      $install_dir,
  String                    $wheel
) {

  $file_ensure = $ensure ? {
    'present' => 'file',
    default   => $ensure
  }

  $cfgdir = "${install_dir}/etc"

  file { "${cfgdir}/nixadmutils.rc":
    ensure  => $file_ensure,
    mode    => '0644',
    content => template('nixadmutils/nixadmutils.rc.erb'),
    require => File[$cfgdir],
  }
}
