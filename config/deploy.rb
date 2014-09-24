#$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
#require "rvm/capistrano"
load 'deploy'
require "bundler/capistrano"
load 'deploy/assets'
require 'sidekiq/capistrano'
load "config/recipes/base"

set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

default_run_options[:pty] = true

set :keep_releases, 10 
set :application, 'xxx'
set :scm, "git"
set :repository, "git@xxx.xxx.xxx.xxx:/gitrepo/app.git"

set :deploy_to, "/home/bc/apps/#{application}"

set :user, "xxx" #proc { Capistrano::CLI.password_prompt("Server User: ") }
set :password, "xxx" #proc { Capistrano::CLI.password_prompt("Server Password : ") }
set :use_sudo, false

task :uname do
  run "uname -a"
end

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_release} && touch tmp/restart.txt"
  end

  task :symlink_shared, :on_no_matching_servers => :continue do
    run "cd #{shared_path}/config/ && cp database.example.yml database.yml", :only => {:primary => true}
    run "cd #{shared_path}/config/ && cp database.example.slave.yml database.yml", :only => {:slave => true}
    run "ln -nfs #{shared_path}/bundle #{release_path}/vendor/bundle"
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/nohup.out #{release_path}/nohup.out"
    run "ln -nfs #{shared_path}/public/sitemap #{release_path}/public/sitemap", :only => {:primary => true}
  end

  task :cache_dir_shared, :only => {:primary => true} do
    run "cd #{release_path}/ && mkdir -p tmp/cache"
    run "ln -nfs #{shared_path}/caches/products #{release_path}/tmp/cache/products"
  end

  desc "Sync the shared directory."
  task :shared do
    find_servers.each do |server|
      system "rsync -vr --exclude='.svn' --exclude='locales' --exclude='initializers' config #{user}@#{server}:#{shared_path}/"
    end
  end

  desc "Update the crontab file"
  task :update_crontab, :roles => :app do
    run "cd #{current_release} && bundle exec whenever --update-crontab #{application}"
  end

  desc "Sync the public/assets directory."
  task :sync_assets do
    system "rsync -vr --exclude='.DS_Store' public/assets #{user}@#{application}:#{shared_path}/"
  end
end

before "bundle:install", "deploy:symlink_shared"
before "deploy:create_symlink", "deploy:cache_dir_shared"
#before "deploy:restart", "deploy:migrate"
