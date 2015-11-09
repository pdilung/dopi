#
# SSH custom command
#
module Dopi
  class Command
    class Ssh
      class PuppetAgentRun < Dopi::Command::Ssh::Custom

        def initialize(command_parser, step, node, is_verify_command)
          command_parser.overwrite_defaults = { :plugin_timeout => 1800 }
          super(command_parser, step, node, is_verify_command)
        end

        def exec
          'puppet agent --test --color false'
        end

        def expect_exit_codes_defaults
          [ 0, 2 ]
        end

        def parse_output_defaults
          { :error => [
              '^Error:'
            ],
            :warning => [
              '^Warning:'
            ]
          }
        end

      end
    end
  end
end
