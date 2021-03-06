# == Define: logstash::input::snmptrap
#
#   Read snmp trap messages as events  Resulting @message looks like :
#   #&lt;SNMP::SNMPv1Trap:0x6f1a7a4
#   @varbindlist=[#&lt;SNMP::VarBind:0x2d7bcd8f @value="teststring",
#   @name=[1.11.12.13.14.15]&gt;],
#   @timestamp=#&lt;SNMP::TimeTicks:0x1af47e9d @value=55&gt;,
#   @generictrap=6,   @enterprise=[1.2.3.4.5.6], @sourceip="127.0.0.1",
#   @agentaddr=#&lt;SNMP::IpAddress:0x29a4833e
#   @value="\xC0\xC1\xC2\xC3"&gt;,   @specifictrap=99&gt;
#
#
# === Parameters
#
# [*add_field*]
#   Add a field to an event
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*codec*]
#   The codec used for input data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*community*]
#   SNMP Community String to listen for.
#   Value type is string
#   Default value: "public"
#   This variable is optional
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*host*]
#   The address to listen on
#   Value type is string
#   Default value: "0.0.0.0"
#   This variable is optional
#
# [*port*]
#   The port to listen on. Remember that ports less than 1024 (privileged
#   ports) may require root to use. hence the default of 1062.
#   Value type is number
#   Default value: 1062
#   This variable is optional
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*type*]
#   Add a 'type' field to all events handled by this input.  Types are
#   used mainly for filter activation.  If you create an input with type
#   "foobar", then only filters which also have type "foobar" will act on
#   them.  The type is also stored as part of the event itself, so you can
#   also use the type to search for in the web interface.  If you try to
#   set a type on an event that already has one (for example when you send
#   an event from a shipper to an indexer) then a new input will not
#   override the existing type. A type set at the shipper stays with that
#   event for its life even when sent to another LogStash server.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*yamlmibdir*]
#   directory of YAML MIB maps  (same format ruby-snmp uses)
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*instances*]
#   Array of instance names to which this define is.
#   Value type is array
#   Default value: [ 'array' ]
#   This variable is optional
#
# === Extra information
#
#  This define is created based on LogStash version 1.2.2.dev
#  Extra information about this input can be found at:
#  http://logstash.net/docs/1.2.2.dev/inputs/snmptrap
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::snmptrap (
  $add_field      = '',
  $codec          = '',
  $community      = '',
  $debug          = '',
  $host           = '',
  $port           = '',
  $tags           = '',
  $type           = '',
  $yamlmibdir     = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_snmptrap_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/snmptrap/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_snmptrap_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/snmptrap/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($community != '') {
    validate_string($community)
    $opt_community = "  community => \"${community}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($yamlmibdir != '') {
    validate_string($yamlmibdir)
    $opt_yamlmibdir = "  yamlmibdir => \"${yamlmibdir}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n snmptrap {\n${opt_add_field}${opt_codec}${opt_community}${opt_debug}${opt_host}${opt_port}${opt_tags}${opt_type}${opt_yamlmibdir} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
