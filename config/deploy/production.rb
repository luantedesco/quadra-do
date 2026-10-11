server "163.176.203.23", user: "deploy", roles: %w[web app db]

set :branch, ENV["BRANCH"]
set :require_release_tag, true
set :ssh_options, { forward_agent: true, keys: %w[~/.ssh/id_oracle_vps] }
