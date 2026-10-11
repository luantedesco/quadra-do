lock "~> 3.20.1"

set :application, "quadra-do"
set :repo_url, "git@github.com:luantedesco/quadra-do.git"
set :deploy_to, "/home/deploy/apps/#{fetch(:application)}"
set :keep_releases, 5

set :rbenv_type, :user
set :rbenv_ruby, File.read(".ruby-version").strip

append :linked_files, "config/master.key"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "storage"

set :puma_systemctl_user, :system
set :puma_service_unit_type, "notify"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
