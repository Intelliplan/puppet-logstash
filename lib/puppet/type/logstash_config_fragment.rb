Puppet::Type.newtype(:logstash_config_fragment) do

  @doc = ""

  newparam(:name, :namevar => true) do
    desc "Unique name"
  end

  newparam(:plugin_type) do
    desc "Plugin type"
  end

  newparam(:content) do
    desc "content"
  end

  newparam(:order) do
    desc "Order"
    defaultto '10'
    validate do |val|
      fail Puppet::ParseError, "only integers > 0 are allowed and not '#{val}'" if val !~ /^\d+$/
    end
  end

  newparam(:tag) do
    desc "Tag"
  end

  validate do
    # think up some validation
  end

end
