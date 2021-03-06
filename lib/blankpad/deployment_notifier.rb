require 'etc'

module Blankpad
  # A Capistrano plugin to send deployment notifications
  module DeploymentNotifier
    VERSION = File.read(File.dirname(__FILE__) + "/../../VERSION").strip.split(".")

    @@recipients = []
    def self.recipients
      @@recipients
    end

    def self.recipients=(recipients)
      @@recipients = recipients
    end
    
    @@from = ""
    def self.from
      @@from
    end

    def self.from=(from)
      @@from = from
    end
    
    def self.deployer
      Etc.getlogin
    end

    # Responsible for taking the e-mail to send, and sending it using the remote
    # server's sendmail command.
    class Mailer
      attr_reader :capistrano
      
      def initialize(capistrano)
        @capistrano = capistrano
      end

      # Delivers a notification e-mail
      def deliver!
        capistrano.run(delivery_command)
      end
      
      # Constructs the final command which will be sent run on the server.
      def delivery_command
        "echo -en '#{message}' | #{mta_command}"
      end

      def mta_command
        "/usr/sbin/sendmail #{DeploymentNotifier.recipients.join(" ")}"
      end

      def message
        Message.new(capistrano, Blankpad::DeploymentNotifier.deployer).to_s.gsub(/\n/, "\\n")
      end
    end

    class Message
      attr_reader :capistrano
      
      def initialize(capistrano, deployer)
        @capistrano = capistrano
        @deployer = deployer
      end
      
      def headers
        {
          "Subject"  => "[DEPLOY] #{capistrano[:application]} #{capistrano[:stage]}",
          "From"     => DeploymentNotifier.from,
          "To"       => DeploymentNotifier.recipients.join(", "),
          "X-Mailer" => "DeploymentNotifier"
        }
      end

      def body
        body = <<EOM
#{@deployer} has deployed revision #{capistrano[:current_revision]} of #{capistrano[:application]} to #{capistrano[:stage]}

Application: #{capistrano[:application]}
Stage: #{capistrano[:stage]}
Repository: #{capistrano[:repository]}
Current Revision: #{capistrano[:current_revision]}
Previous revision: #{capistrano[:previous_revision]}
EOM
        body = capistrano[:message] + "\n\n#{body}" if capistrano[:message]

        body
      end

      def to_s
        headers.collect { |key, value| "#{key}: #{value}" }.join("\n") << "\n\n#{body}"
      end
    end
  end
end

if Object.const_defined?("Capistrano")
  Capistrano::Configuration.instance(:must_exist).load do
    namespace "deploy" do
      desc "Send a notification e-mail to people who want one"
      task :notify do
        Blankpad::DeploymentNotifier::Mailer.new(self).deliver!
      end
    end
  end
end
