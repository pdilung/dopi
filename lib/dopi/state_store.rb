#
# This is the DOPi state store which persists the state
# of the steps between and during runs.
#
module Dopi
  class StateStore

    def initialize(plan_name, plan_store)
      @plan_store  = plan_store
      @plan_name   = plan_name
      @state_store = @plan_store.state_store(plan_name, 'dopi')
    end

    def update(options = {})
      if options[:clear]
        clear(options)
      elsif options[:ignore]
        ignore(options)
      else
        update_state(options)
      end
    rescue DopCommon::UnknownVersionError => e
      Dopi.log.warn("The state has an unknown plan version #{e.message}.")
      Dopi.log.warn("Please update with the 'clear' or 'ignore' option")
    rescue => e
      Dopi.log.error("An error occured during update: #{e.message}")
      Dopi.log.error("Please update with the 'clear' or 'ignore' option")
    end

    def persist_state(plan)
      @state_store.transaction do
        plan_state = plan.state_hash
        Dopi.log.debug('Persisting plan state:')
        Dopi.log.debug(plan_state)
        @state_store[:state] = plan_state
      end
    end

    def state_hash
      @state_store.transaction(true) do
        @state_store[:state] || {}
      end
    end

    def method_missing(m, *args, &block)
      @state_store.send(m, *args, &block)
    end

  private

    def clear(options)
      @state_store.transaction do
        Dopi.log.debug("Clearing the state for plan #{@plan_name}")
        ver = @plan_store.show_versions(@plan_name).last
        plan = Dopi::Plan.new(@plan_store.get_plan(@plan_name))
        @state_store[:state] = plan.state_hash
        @state_store[:version] = ver
      end
    end

    def ignore(options)
      @state_store.transaction do
        ver = @plan_store.show_versions(@plan_name).last
        Dopi.log.debug("Ignoring update and setting state version of plan #{@plan_name} to #{ver}")
        @state_store[:version] = ver
      end
    end

    def update_state(options)
      @state_store.update do |plan_diff|
        Dopi.log.debug("Updating plan #{@plan_name}. This is the diff:")
        Dopi.log.debug(plan_diff.to_s)

        plan_diff.each do |patch|
          match ||= update_rule_steps(patch)
          unless match
            Dopi.log.debug("No rule matched, ignoring patch: #{patch.to_s}")
          end
        end
      end
    end

    def update_rule_steps(patch)
      match = /^steps\.?(\w*)\[(\d+)\](.*)/.match(patch[1])
      if match
        step_set = match[1].empty? ? 'default' : match[1]
        step_nr  = match[2].to_i
        rest     = match[3]
        unless update_rule_commands(patch, step_set, step_nr, rest)
          case patch[0]
          when '+' then add_step(step_set, step_nr)
          when '-' then del_step(step_set, step_nr)
          else
            Dopi.log.debug("Step changed, ignoring patch: #{patch.to_s}")
          end
        end
        return true
      end
      return false
    end

    def update_rule_commands(patch, step_set, step_nr, rest)
      match = /^\.commands?\[(\d+)\](.*)/.match(rest)
      if match
        command_nr = match[1]
        if /^\.verify_command/.match(rest)
          Dopi.log.debug("Change in verify_command only, ignoring patch: #{patch.to_s}")
        else
          case patch[0]
          when '+' then add_command(step_set, step_nr)
          when '-' then del_command(step_set, step_nr)
          else
            Dopi.log.debug("Command changed, ignoring patch: #{patch.to_s}")
          end
        end
        return true
      end
      return false
    end

    def add_step(step_set, step_nr)
      @state_store[:state][:step_sets][step_set].insert(step_nr, {})
    end

    def del_step(step_set, step_nr)
      @state_store[:state][:step_sets][step_set].delete_at(step_nr)
    end

    def add_command(step_set, step_nr, command_nr)
      @state_store[:state][:step_sets][step_set][step_nr].each do |node|
        node.insert(command_nr, {:command_state => :ready})
      end
    end

    def del_command(step_set, step_nr, command_nr)
      @state_store[:state][:step_sets][step_set][step_nr].each do |node|
        node.delete_at(command_nr)
      end
    end

  end

  class StateStoreObserver

    def initialize(plan, state_store)
      @plan        = plan
      @state_store = state_store
    end

    def update(notify_only = false)
      @state_store.persist_state(@plan)
    end

  end
end
