#
# Configration for DOPi
#
# Configure the module in a block:
#
#   Dopi.configure do |config|
#     config.use_hiera = true
#   end
#

module Dopi

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @configuration = config
  end

  def self.configure
    yield configuration
  end

  def self.configure=(options_hash)
    options_hash.each do |key, value|
      variable_name = '@' + key.to_s
      if configuration.instance_variable_defined?( variable_name )
        configuration.instance_variable_set( variable_name , value )
      end
    end
  end

  class Configuration
    attr_accessor :use_hiera, :hiera_yaml, :facts_dir
    attr_accessor :role_variable, :role_default
    attr_accessor :ssh_user, :ssh_key

    def initialize
      # Hiera defaults
      @use_hiera  = false
      @hiera_yaml = '/etc/hiera.yaml'
      @facts_dir  = '/var/lib/puppet/yaml/facts/'

      # Role defaults
      @role_variable = 'role'
      @role_default  = nil

      # SSH defaults
      @ssh_user = 'root'
      @ssh_key  = File.join(ENV['HOME'], '.ssh/id_dsa')
    end
 
  end

end
