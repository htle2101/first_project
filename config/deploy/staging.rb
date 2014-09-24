load "config/recipes/nginx"
load "config/recipes/unicorn"
server 'www.bctest.com', :app, :web, :db, :primary => true
set :application, 'www.bctest.com'
set :deploy_to, "/home/bc/apps/www.bctest.com"
set :branch, "manage_orders"
set :rails_env, "staging"
set :default_environment, {
  'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
}

