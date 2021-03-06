# == Define: logstash::input::unix
#
#   Read events over a UNIX socket.  Like stdin and file inputs, each
#   event is assumed to be one line of text.  Can either accept
#   connections from clients or connect to a server, depending on mode.
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
# [*data_timeout*]
#   The 'read' timeout in seconds. If a particular connection is idle for
#   more than this timeout period, we will assume it is dead and close it.
#   If you never want to timeout, use -1.
#   Value type is number
#   Default value: -1
#   This variable is optional
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*force_unlink*]
#   Remove socket file in case of EADDRINUSE failure
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*mode*]
#   Mode to operate in. server listens for client connections, client
#   connects to a server.
#   Value can be any of: "server", "client"
#   Default value: "server"
#   This variable is optional
#
# [*path*]
#   When mode is server, the path to listen on. When mode is client, the
#   path to connect to.
#   Value type is string
#   Default value: None
#   This variable is required
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
#  http://logstash.net/docs/1.2.2.dev/inputs/unix
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::unix (
  $path,
  $codec          = '',
  $data_timeout   = '',
  $debug          = '',
  $force_unlink   = '',
  $mode           = '',
  $add_field      = '',
  $tags           = '',
  $type           = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_unix_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/unix/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_unix_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/unix/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($force_unlink != '') {
    validate_bool($force_unlink)
    $opt_force_unlink = "  force_unlink => ${force_unlink}\n"
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

  if ($data_timeout != '') {
    if ! is_numeric($data_timeout) {
      fail("\"${data_timeout}\" is not a valid data_timeout parameter value")
    } else {
      $opt_data_timeout = "  data_timeout => ${data_timeout}\n"
    }
  }

  if ($mode != '') {
    if ! ($mode in ['server', 'client']) {
      fail("\"${mode}\" is not a valid mode parameter value")
    } else {
      $opt_mode = "  mode => \"${mode}\"\n"
    }
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($path != '') {
    validate_string($path)
    $opt_path = "  path => \"${path}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n unix {\n${opt_add_field}${opt_codec}${opt_data_timeout}${opt_debug}${opt_force_unlink}${opt_mode}${opt_path}${opt_tags}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
