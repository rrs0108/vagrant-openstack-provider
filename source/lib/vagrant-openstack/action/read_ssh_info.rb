require "log4r"

module VagrantPlugins
  module Openstack
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call(env)
        end

        def read_ssh_info(env)
          client = env[:openstack_client]
          machine = env[:machine]
          config = env[:machine].provider_config
          @logger.debug(config)
          return nil if machine.id.nil?
          begin
            details = client.get_server_details(env, machine.id)
          rescue Exception => e
            # The machine can't be found
            @logger.error(e)
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

          for addr in details['addresses']['private']
            if addr['OS-EXT-IPS:type'] == 'floating'
              host = addr['addr']
            end
          end

          return {
            # Usually there should only be one public IP
            :host => host,
            :port => 22,
            :username => config.ssh_username
          }
        end
      end
    end
  end
end
