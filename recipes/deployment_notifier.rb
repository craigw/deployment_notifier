require 'blankpad/deployment_notifier'
after :"deploy:restart", :"deploy:notify"