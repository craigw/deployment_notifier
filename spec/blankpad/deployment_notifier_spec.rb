require File.dirname(__FILE__) + "/../spec_helper"

describe Blankpad::DeploymentNotifier do
  describe "the version number" do
    it "should not be nil" do
      Blankpad::DeploymentNotifier::VERSION.should_not be_nil
    end
    
    it "should be a three element array" do
      Blankpad::DeploymentNotifier::VERSION.should have(3).items
    end

    it "should be the same as the contents of VERSION" do
      expected_version = File.read(File.dirname(__FILE__) + "/../../VERSION").strip.split(".")
      Blankpad::DeploymentNotifier::VERSION.should eql(expected_version)
    end
  end
  
  describe "configuration" do
    it "should allow the recipients list to be set and retriveed" do
      Blankpad::DeploymentNotifier.should respond_to(:recipients)
      Blankpad::DeploymentNotifier.should respond_to(:recipients=)
    end

    it "should return the same set of recipients" do
      recipients = [ "one@example.org" ]
      
      Blankpad::DeploymentNotifier.recipients = recipients
      Blankpad::DeploymentNotifier.recipients.should eql(recipients)
    end

    it "should allow the from address to be set and retrieved" do
      from = "Example Deployer <deploy@example.org>"

      Blankpad::DeploymentNotifier.from = from
      Blankpad::DeploymentNotifier.from.should eql(from)
    end

    it "should allow the person deploying to be retrieved" do
      Etc.stub!(:getlogin).and_return("jon")
      Blankpad::DeploymentNotifier.deployer.should eql("jon")
    end
  end

  describe "the mailer" do
    before(:each) do
      @capistrano = mock("Capistrano")
      @mailer = Blankpad::DeploymentNotifier::Mailer.new(@capistrano)
    end
    
    it "should provide a way of accessing the Capistrano instance" do
      @mailer.should respond_to(:capistrano)
    end

    it "should use the first argument as a Cap instance" do
      @mailer.capistrano.should eql(@capistrano)
    end
    
    describe "mail delivery" do
      it "provide a method to deliver notification e-mails" do
        @mailer.should respond_to(:deliver!)
      end

      it "should have a method which builds the delivery command" do
        @mailer.should respond_to(:delivery_command)
      end
      
      it "should run the delivery command with deliver! is called, and pass the result to run" do
        @mailer.should_receive(:delivery_command).and_return("")
        @capistrano.should_receive(:run).with("")
        
        @mailer.deliver!
      end

      describe "the delivery command" do
        it "should be made up of a message, which is piped to the MTA" do
          @mailer.should_receive(:message).and_return("The message")
          @mailer.should_receive(:mta_command).and_return("/usr/sbin/sendmail null@example.org")

          @mailer.delivery_command.should eql("echo -en 'The message' | /usr/sbin/sendmail null@example.org")
        end
      end

      it "should have a method to retrieve the MTA command" do
        @mailer.should respond_to(:mta_command)
      end

      describe "the mta command" do
        it "should be sendmail, followed by a space seperated list of recipients" do
          Blankpad::DeploymentNotifier.recipients = %w[one@example.org two@example.org]
          
          @mailer.mta_command.should eql('/usr/sbin/sendmail one@example.org two@example.org')
        end
      end

      it "should have a method to retrieve the message to send" do
        @mailer.should respond_to(:message)
      end

      describe "the message method" do
        it "should create a new Message object, and return it's string representation" do
          message = mock("a message")
          message.should_receive(:to_s).and_return("the message to send")

          Blankpad::DeploymentNotifier::Message.stub!(:new).and_return(message)
          @mailer.message
        end

        it "should escape any newline characters" do
          message = mock("a message")
          message.should_receive(:to_s).and_return("the message to send\n")

          Blankpad::DeploymentNotifier::Message.stub!(:new).and_return(message)
          @mailer.message.should match(/\\n/)
        end
      end
    end
  end

  describe "a message" do
    before(:each) do
      @capistrano = stub("Capistrano")
      @message = Blankpad::DeploymentNotifier::Message.new(@capistrano, "deployer")
    end
    
    def add_property(name, value)
      @capistrano.stub!(:[]).with(name).and_return(value)
    end

    it "should have a method to retreive the headers" do
      @message.should respond_to(:headers)
    end

    describe "the message headers" do
      before(:each) do
        add_property(:application, "application_name")
        add_property(:stage, "stage")
      end

      it "should set the subject to '[DEPLOY] application_name stage' by default" do
        @message.headers["Subject"].should eql("[DEPLOY] application_name stage")
      end

      it "should set the from address to the one configured" do
        Blankpad::DeploymentNotifier.from = "Deployment Notifier <deploy@example.org>"

        @message.headers["From"].should eql("Deployment Notifier <deploy@example.org>")
      end

      it "should set the mailer to 'DeploymentNotifier'" do
        @message.headers["X-Mailer"].should eql("DeploymentNotifier")
      end

      it "should set the to address to the recipients" do
        Blankpad::DeploymentNotifier.recipients = ["One <one@example.org>", "Two <two@example.org>"]
        @message.headers["To"].should eql("One <one@example.org>, Two <two@example.org>")
      end
    end
    
    it "should have a method to retrieve the message body" do
      @message.should respond_to(:body)
    end

    describe "the message body" do
      properties = {
        :application        => "application_name",
        :stage              => "stage",
        :repository         => "git://github.com/example/example_org.git",
        :current_revision   => "f8ds98f0sd8f0sd8",
        :previous_revision  => "f9s8fsd8f0sd0sdf"
      }
      
      before(:each) do
        @capistrano.stub!(:[]).and_return(nil) 
        properties.each do |name, value|
          add_property(name, value)
        end
        
        Etc.stub!(:getlogin).and_return("deployer")
      end
            
      it "should include a summary" do
        @message.body.should match(/deployer has deployed revision f8ds98f0sd8f0sd8 of application_name to stage/i)
      end

      properties.each do |name, value|
        it "should include the #{name} property" do
          @message.body.should match(/#{name.to_s.gsub("_", " ")}: #{value}/i)
        end
      end

      it "should include the explanation when a message has been set" do
        add_property :message, "Because I feel like it."

        @message.body.should match(/Because I feel like it./)
      end
    end

    it "should return the full message with headers on to_s" do
      @message.stub!(:headers).and_return({"One" => "Header 1", "Two" => "Header 2"})
      @message.stub!(:body).and_return("The body")

      @message.to_s.should eql(%Q{One: Header 1
Two: Header 2

The body})
    end
  end
end
