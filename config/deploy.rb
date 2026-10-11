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

namespace :deploy do
  desc "Aborta o deploy quando :branch não é uma tag SemVer que já existe no GitHub"
  task :validate_release_branch do
    next unless fetch(:require_release_tag, false)

    tag = fetch(:branch).to_s
    unless tag.match?(/\Av\d+\.\d+\.\d+\z/)
      abort "BRANCH inválida: '#{tag}'. Produção exige uma tag SemVer, ex.: BRANCH=v1.2.3 cap production deploy"
    end

    run_locally do
      if capture(:git, "ls-remote", "--tags", fetch(:repo_url), "refs/tags/#{tag}").strip.empty?
        abort "Tag '#{tag}' não existe em #{fetch(:repo_url)}. Crie a release no GitHub antes do deploy."
      end
    end
  end
end

before "deploy:starting", "deploy:validate_release_branch"
