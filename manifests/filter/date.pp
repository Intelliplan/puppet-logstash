# == Define: logstash::filter::date
#
#   The date filter is used for parsing dates from fields and using that
#   date or timestamp as the timestamp for the event.  For example, syslog
#   events usually have timestamps like this:  "Apr 17 09:32:01"   You
#   would use the date format "MMM dd HH:mm:ss" to parse this.  The date
#   filter is especially important for sorting events and for backfilling
#   old data. If you don't get the date correct in your event, then
#   searching for them later will likely sort out of order.  In the
#   absence of this filter, logstash will choose a timestamp based on the
#   first time it sees the event (at input time), if the timestamp is not
#   already set in the event. For example, with file input, the timestamp
#   is set to the time of each read.
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   date {     add_field =&gt; [
#   "foo_%{somefield}", "Hello world, from %{host}" ]   } }   If the event
#   has field "somefield" == "hello" this filter, on success, would add
#   field "foo_hello" if it is present, with the value above and the
#   %{host} piece replaced with that value from the event.
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*add_tag*]
#   If this filter is successful, add arbitrary tags to the event. Tags
#   can be dynamic and include parts of the event using the %{field}
#   syntax. Example:  filter {   date {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*locale*]
#   specify a locale to be used for date parsing. If this is not specified
#   the platform default will be used  The locale is mostly necessary to
#   be set for parsing month names and weekday names
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*match*]
#   The date formats allowed are anything allowed by Joda-Time (java time
#   library): You can see the docs for this format here:
#   joda.time.format.DateTimeFormat  An array with field name first, and
#   format patterns following, [ field, formats... ]  If your time field
#   has multiple possible formats, you can do this:  match =&gt; [
#   "logdate", "MMM dd YYY HH:mm:ss",           "MMM  d YYY HH:mm:ss",
#   "ISO8601" ]   The above will match a syslog (rfc3164) or iso8601
#   timestamp.  There are a few special exceptions, the following format
#   literals exist to help you save time and ensure correctness of date
#   parsing.  "ISO8601" - should parse any valid ISO8601 timestamp, such
#   as 2011-04-19T03:44:01.103Z "UNIX" - will parse unix time in seconds
#   since epoch "UNIX_MS" - will parse unix time in milliseconds since
#   epoch "TAI64N" - will parse tai64n time values For example, if you
#   have a field 'logdate' and with a value that looks like 'Aug 13 2010
#   00:03:44', you would use this configuration:  filter {   date {
#   match =&gt; [ "logdate", "MMM dd YYYY HH:mm:ss" ]   } }
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   date {     remove_field =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the field with name
#   "foo_hello" if it is present
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*remove_tag*]
#   If this filter is successful, remove arbitrary tags from the event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   syntax. Example:  filter {   date {     remove_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the tag "foo_hello" if
#   it is present
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*target*]
#   Store the matching timestamp into the given target field.  If not
#   provided, default to updating the @timestamp field of the event.
#   Value type is string
#   Default value: "@timestamp"
#   This variable is optional
#
# [*timezone*]
#   specify a timezone canonical ID to be used for date parsing. The valid
#   ID are listed on http://joda-time.sourceforge.net/timezones.html
#   Useful in case the timezone cannot be extracted from the value, and is
#   not the platform default If this is not specified the platform default
#   will be used. Canonical ID is good as it takes care of daylight saving
#   time for you For example, America/Los_Angeles or Europe/France are
#   valid IDs
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*order*]
#   The order variable decides in which sequence the filters are loaded.
#   Value type is number
#   Default value: 10
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
#  Extra information about this filter can be found at:
#  http://logstash.net/docs/1.2.2.dev/filters/date
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::date (
  $add_field    = '',
  $add_tag      = '',
  $locale       = '',
  $match        = '',
  $remove_field = '',
  $remove_tag   = '',
  $target       = '',
  $timezone     = '',
  $order        = 10,
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_date_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/date/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_date_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/date/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($add_tag != '') {
    validate_array($add_tag)
    $arr_add_tag = join($add_tag, '\', \'')
    $opt_add_tag = "  add_tag => ['${arr_add_tag}']\n"
  }

  if ($match != '') {
    validate_array($match)
    $arr_match = join($match, '\', \'')
    $opt_match = "  match => ['${arr_match}']\n"
  }

  if ($remove_field != '') {
    validate_array($remove_field)
    $arr_remove_field = join($remove_field, '\', \'')
    $opt_remove_field = "  remove_field => ['${arr_remove_field}']\n"
  }

  if ($remove_tag != '') {
    validate_array($remove_tag)
    $arr_remove_tag = join($remove_tag, '\', \'')
    $opt_remove_tag = "  remove_tag => ['${arr_remove_tag}']\n"
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($order != '') {
    if ! is_numeric($order) {
      fail("\"${order}\" is not a valid order parameter value")
    }
  }

  if ($timezone != '') {
    validate_string($timezone)
    $opt_timezone = "  timezone => \"${timezone}\"\n"
  }

  if ($target != '') {
    validate_string($target)
    $opt_target = "  target => \"${target}\"\n"
  }

  if ($locale != '') {
    validate_string($locale)
    $opt_locale = "  locale => \"${locale}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "filter {\n date {\n${opt_add_field}${opt_add_tag}${opt_locale}${opt_match}${opt_remove_field}${opt_remove_tag}${opt_target}${opt_timezone} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
