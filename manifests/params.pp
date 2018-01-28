# nixadmutils::params
#
# Params class for nixsdmtuils toolset
#
# @summary Params class for nixsdmtuils toolset
#
# @example
#   include nixadmutils::params
class nixadmutils::params {

  $wheelgroup = $::osfamily ? {
    'Debian' => 'sudo',
    default  => 'wheel',
  }
}
