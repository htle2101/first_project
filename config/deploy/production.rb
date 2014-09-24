#load "config/recipes/monit"
server 'www.buychina.com', :app, :web, :db, :primary => true
server '209.160.24.254', :lib, :slave => true
set :branch, "deploy"
set :rails_env, "production"
set :default_environment, {
  'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
}

before "deploy:restart", "deploy:update_crontab"
