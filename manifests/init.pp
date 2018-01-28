# nixadmutils
#
# Class to manage nixadmutils toolset
#
# @summary Class to manage nixadmutils toolset
#
# @example
#   include nixadmutils
class nixadmutils (
  $wheelgroup = $nixadmutils::params::wheelgroup,
) inherits ::nixadmutils::params {

  $nixadmutilsdir = '/opt/nixadmutils'

  File {
    owner => 'root',
    group => 'root',
  }

  include nixadmutils::install
  include nixadmutils::config
}
