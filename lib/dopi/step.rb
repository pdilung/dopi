#
# Step
#
require 'forwardable'
require 'parallel'

module Dopi
  class Step
    extend Forwardable
    include Dopi::State

    DEFAULT_MAX_IN_FLIGHT = 3

    def initialize(step_parser, plan, nodes = [])
      @step_parser = step_parser
      @plan        = plan
      @nodes       = nodes

      commands.each{|command| state_add_child(command)}
    end

    def_delegators :@step_parser, :name

    def run
      if state_done?
        Dopi.log.info("Step '#{name}' is in state 'done'. Skipping")
        return
      end
      state_run
      Dopi.log.info("Starting to run step '#{name}'")
      commands_copy = commands.dup
      if canary_host
        pick = rand(commands_copy.length - 1)
        commands_copy.delete_at(pick).meta_run
      end
      unless state_failed?
        number_of_threads = max_in_flight == -1 ? commands_copy.length : max_in_flight
        Parallel.each(commands_copy, :in_threads => number_of_threads) do |command|
          raise Parallel::Break if state_failed?
          command.meta_run
        end
      end
      Dopi.log.info("Step '#{name}' successfully finished.") if state_done?
      Dopi.log.error("Step '#{name}' failed! Stopping execution.") if state_failed?
    end

    def max_in_flight
      @max_in_flight ||= @step_parser.max_in_flight || @plan.max_in_flight || DEFAULT_MAX_IN_FLIGHT
    end

    def canary_host
      @canary_host ||= @step_parser.canary_host || @plan.canary_host
    end

    def valid?
      if @nodes.empty?
        Dopi.log.error("Step '#{name}': Nodes list is empty")
        return false
      end
      command_plugin_valid?
    end

    def command_plugin_valid?
      begin
        commands.first.meta_valid?
      rescue PluginLoaderError => e
        Dopi.log.error("Step '#{name}': Can't load plugin '#{@step_parser.command.plugin}': #{e.message}")
        false
      end
    end

    def commands
      @commands ||= @nodes.map do |node|
        Dopi::Command.create_plugin_instance(@step_parser.command, self, node)
      end
    end

  end
end
