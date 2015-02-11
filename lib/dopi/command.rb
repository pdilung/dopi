#
# This class loades the dopi command plugins
#
require 'forwardable'
require 'timeout'


module Dopi
  class CommandParsingError < StandardError
  end

  class CommandExecutionError < StandardError
  end

  class Command
    extend Forwardable
    include Dopi::State

    def self.inherited(klass)
      PluginManager << klass
    end

    def self.create_plugin_instance(plugin_name, node, command_parser)
      plugin_type = PluginManager.get_plugin_name(self) + '/'
      Dopi.log.debug("Creating instance of plugin #{plugin_type + plugin_name}")
      PluginManager.create_instance(plugin_type + plugin_name, node, command_parser)
    end

    def initialize(node, command_parser)
      @node           = node
      @command_parser = command_parser
    end

    def_delegator :@command_parser, :plugin, :name

    def meta_run
      state_run
      Dopi.log.debug("Running command #{name} on #{@node.name}")
      begin
        Timeout::timeout(plugin_timeout) do
          if state_running? && verify_commands.any?
            state_finish if verify_commands.all? {|command| command.meta_run}
          end
          if state_running?
            run ? state_finish : state_fail
          else
            Dopi.log.info("Nothing to do for command #{name} on #{@node.name}")
          end
        end
      rescue Timeout::Error
        state_fail
        Dopi.log.error("Command #{name} timed out on #{@node.name}")
      rescue Exception => e
        state_fail
        raise e
      end
    end

  private

    def_delegator  :@command_parser, :verify_commands, :parsed_verify_commands
    def_delegators :@command_parser, :hash, :plugin_timeout

    def run
      raise Dopi::CommandExecutionError, "No run method implemented in plugin #{name}"
    end

    def verify_commands
      @verify_commands ||= parsed_verify_commands.map do |command|
        Dopi::Command.create_plugin_instance(command.plugin, @node, command)
      end
    end

  end
end


# load standard command plugins
require 'dopi/command/dummy'
require 'dopi/command/custom'
require 'dopi/command/ssh/custom'
require 'dopi/command/ssh/puppet_agent_run'
require 'dopi/command/ssh/wait_for_login'

# TODO: load plugins from the plugin paths
