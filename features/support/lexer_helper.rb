FIXTURES = YAML.load_file File.dirname(__FILE__) + "/ami_fixtures.yml"

def metaclass
  class << self
    self
  end
end

def meta_eval(&block)
  metaclass.instance_eval &block
end

def meta_def(name, &block)
  meta_eval do
    define_method name, &block
  end
end

def fixture(path, overrides = {})
  path_segments = path.split '/'
  selected_event = path_segments.inject(FIXTURES.clone) do |hash, segment|
    raise ArgumentError, path + " not found!" unless hash
    hash[segment.to_sym]
  end

  # Downcase all keys in the event and the overrides
  selected_event = selected_event.inject({}) do |downcased_hash,(key,value)|
    downcased_hash[key.to_s.downcase] = value
    downcased_hash
  end

  overrides = overrides.inject({}) do |downcased_hash,(key,value)|
    downcased_hash[key.to_s.downcase] = value
    downcased_hash
  end

  # Replace variables in the selected_event with any overrides, ignoring case of the key
  keys_with_variables = selected_event.select { |(key, value)| value.kind_of?(Symbol) || value.kind_of?(Hash) }

  keys_with_variables.each do |original_key, variable_type|
    # Does an override an exist in the supplied list?
    if overriden_pair = overrides.find { |(key, value)| key == original_key }
      # We have an override! Let's replace the template value in the event with the overriden value
      selected_event[original_key] = overriden_pair.last
    else
      # Based on the type, let's generate a placeholder.
      selected_event[original_key] = case variable_type
        when :string
          rand(100000).to_s
        when Hash
          if variable_type.has_key? "one_of"
            # Choose a random possibility
            possibilities = variable_type['one_of']
            possibilities[rand(possibilities.size)]
          else
            raise "Unrecognized Hash fixture property! ##{variable_type.keys.to_sentence}"
          end
        else
          raise "Unrecognized fixture variable type #{variable_type}!"
      end
    end
  end

  hash_to_stanza(selected_event).tap do |event|
    selected_event.each_pair do |key, value|
      event.meta_def(key) { value }
    end
  end
end

def hash_to_stanza(hash)
  ordered_hash = hash.to_a
  starter = hash.find { |(key, value)| key.strip =~ /^(Response|Action)$/i }
  ordered_hash.unshift ordered_hash.delete(starter) if starter
  ordered_hash.inject(String.new) do |stanza,(key, value)|
    stanza + "#{key}: #{value}\r\n"
  end + "\r\n"
end

def format_newlines(string)
  # HOLY FUCK THIS IS UGLY
  tmp_replacement = random_string
  string.gsub("\r\n", tmp_replacement).
         gsub("\n", "\r\n").
         gsub(tmp_replacement, "\r\n")
end

def random_string
  (rand(1_000_000_000_000) + 1_000_000_000).to_s
end

def follows_body_text(name)
  case name
    when "ragel_description"
      "Ragel is a software development tool that allows user actions to
      be embedded into the transitions of a regular expression's corresponding state machine,
      eliminating the need to switch from the regular expression engine and user code execution
      environment and back again."
    when "with_colon_after_first_line"
      "Host                            Username       Refresh State                Reg.Time                 \r\nlax.teliax.net:5060             jicksta            105 Registered           Tue, 11 Nov 2008 02:29:55"
    when "show_channels_from_wayne"
      "Channel              Location             State   Application(Data)\r\n0 active channels\r\n0 active calls"
    when "empty_string"
      ""
  end
end

def syntax_error_data(name)
  case name
    when "immediate_packet_with_colon"
      "!IJ@MHY:!&@B*!B @ ! @^! @ !@ !\r!@ ! @ !@ ! !!m, \n\\n\n"
  end
end
