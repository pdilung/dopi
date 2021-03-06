module Dopi
  module Cli

    def self.run_options(command)
      DopCommon::Cli.node_select_options(command)

      command.desc 'Show only stuff the run would do but don\'t execute commands (verify commands will still be executed)'
      command.default_value false
      command.switch [:noop, :n]

      command.desc 'Select the step set to run (if nothing is specified it will try to run the step set "default")'
      command.default_value 'default'
      command.arg_name 'STEPSET'
      command.flag [:step_set, :s]
    end

    def self.command_run(base)
      base.class_eval do

        desc 'Run the plan'
        arg_name 'id'
        command :run do |c|
          run_options(c)
          c.action do |global_options,options,args|
            help_now!('Specify a plan name to run') if args.empty?
            help_now!('You can only run one plan') if args.length > 1
            options[:run_for_nodes] = DopCommon::Cli.parse_node_select_options(options)
            plan_name = args[0]
            begin
              Dopi.run(plan_name, options)
            rescue Dopi::StateTransitionError => e
              Dopi.log.error(e.message)
              exit_now!("Some steps are in a state where they can't be started again. Try to reset the plan.")
            ensure
              print_state(plan_name)
              exit_now!('Errors during plan run detected!') if Dopi.show(plan_name).state_failed?
            end
          end
        end

        desc 'Add a plan, run it and then remove it again (This is mainly for testing)'
        arg_name 'plan_file'
        command :oneshot do |c|
          run_options(c)
          c.action do |global_options,options,args|
            help_now!('Specify a plan file to add') if args.empty?
            help_now!('You can only add one plan') if args.length > 1
            options[:run_for_nodes] = DopCommon::Cli.parse_node_select_options(options)
            plan_file = args[0]
            plan_name = Dopi.add(plan_file)
            begin
              Dopi.run(plan_name, options)
            ensure
              print_state(plan_name)
              failed = Dopi.show(plan_name).state_failed?
              Dopi.remove(plan_name, true)
              exit_now!('Errors during plan run detected!') if failed
            end
          end
        end

      end
    end

  end
end


