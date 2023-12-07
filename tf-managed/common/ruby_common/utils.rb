# frozen_string_literal: true

# Retrieves an environmental variable, failing if its not set or empty.
def get_and_assert_env_variable(name)
  var = ENV.fetch(name, nil)
  raise "Please set #{name} environmental variable" if var.nil? || var.empty?

  var
end
