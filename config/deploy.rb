require "rvm/capistrano"
#require "capistrano/ext/multistage"
require "bundler/capistrano"

#set :stages, %w(staging production)

set :application, "showip"
set :repository,  "git@github.com:verdor/showip.git"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

# /usr/local/rvm/gems/ruby-2.0.0-p451@showip/bin/thin
set :rvm_ruby_string, 'ruby-2.0.0-p451@showip'
set :rvm_type, :system
#set :rvm_path, '/usr/local/rvm'
#set :rvm_bin_path, '/usr/local/rvm/bin'

set :scm, :git
set :git_shallow_clone, 1
server "192.168.1.10", :app, :web, :db, primary: true
#server "showip.tk", :app, :web, :db, primary: true

set :user, "deploy"
#set :default_shell, "sudo -u www-data /bin/sh"
#set :default_shell, "TERM=dumb sudo -u www-data /bin/sh"
#sudo su - www-data -s /bin/bash
#set :group, "www-data"
set :keep_releases, 5
set :use_sudo, false

#set :port, 22 #sustituye con el puerto que usas
# Capistrano's default location "/u/apps/#{application}"
set :deploy_to, "/var/#{user}/apps/#{application}"
set :deploy_via, :remote_cache

set :branch, "master"

after  "deploy:finalize_update" , "symlinks"
after  "deploy",                  "deploy:cleanup"

namespace :deploy do
  desc "Sube ficheros de configuración"
  task :setup_config, roles: :app do
    #run "mkdir #{shared_path}/config"
    #run "#{try_sudo} mkdir #{shared_path}/config"
    top.upload("config/nginx.conf", "#{shared_path}/nginx.conf", via: :scp)
    top.upload("config/thin_config.yml", "#{shared_path}/thin_config.yml", via: :scp)
    top.upload("config/database.yml", "#{shared_path}/database.yml", via: :scp)
    #top.upload(".rvmrc", "#{shared_path}/.rvmrc", via: :scp)
    top.upload(".versions.conf", "#{shared_path}/.versions.conf", via: :scp)
    #sudo "mv #{shared_path}/config/nginx.conf /etc/nginx/sites-available/showip.jeronima.tk"
    #sudo "ln -nfs /etc/nginx/sites-available/showip.jeronima.tk /etc/nginx/sites-enabled/showip.jeronima.tk"
  end

  after "deploy:setup", "deploy:setup_config"
end

task :symlinks, roles: [:app] do
  run <<-CMD
    ln -s #{shared_path}/cache #{release_path}/public/;
    ln -s #{shared_path}/database.yml #{release_path}/config/;
    ln -s #{shared_path}/thin_config.yml #{release_path}/config/;
    ln -s #{shared_path}/.versions.conf #{release_path}/;
  CMD
end

namespace :deploy do
  desc "Start the Thin processes"
  task :start do
    # cd #{current_path}; bundle exec thin start -C config/thin_config.yml
    run  <<-CMD
      /etc/init.d/showip start
    CMD
  end

  desc "Stop the Thin processes"
  task :stop do
    # cd #{current_path}; bundle exec thin stop -C config/thin_config.yml
    run <<-CMD
      /etc/init.d/showip stop
    CMD
  end

  desc "Restart the Thin processes"
  # cd #{current_path}; bundle exec thin restart -C config/thin_config.yml
  task :restart do
    run <<-CMD
      /etc/init.d/showip restart
    CMD
  end
end
