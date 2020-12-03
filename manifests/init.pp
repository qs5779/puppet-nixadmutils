# nixadmutils
#
# Class to manage nixadmutils toolset
#
# @summary Class to manage nixadmutils toolset
#
# @example
#   include nixadmutils
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
class nixadmutils (
  Enum['present', 'absent'] $ensure,
  Stdlib::Absolutepath      $install_dir,
  String                    $wheel,
  Boolean                   $journal,
) {

  File {
    owner => 'root',
    group => 'root',
  }

  class { 'nixadmutils::install':
    ensure      => $ensure,
    install_dir => $install_dir,
    wheel       => $wheel,
    journal     => $journal,
  }
  -> class { 'nixadmutils::config':
    ensure      => $ensure,
    install_dir => $install_dir,
    wheel       => $wheel,
  }
}
