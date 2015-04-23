include_recipe 'shipper'

app_id = 'myusa'
deploy_to_dir = "/var/www/#{app_id}"

shared_dirs = {
  "bundle" => ".bundle",
  "log" => "log",
  "tmp" => "tmp",
  "system" => "public/system",
  "assets" => "public/assets"
}

shared_files = {
  "config/database.yml" => "config/database.yml",
  "config/newrelic.yml" => "config/newrelic.yml",
  "config/secrets.yml"  => "config/secrets.yml",
  "config/env.sh"       => "config/env.sh"
}

deploy_branch deploy_to_dir do
  repo node['myusa']['repo']
  revision node['myusa']['branch'] # or "HEAD" or "TAG_for_1.0" or (subversion) "1234"
  user node['myusa']['user']['username']
  migrate false
  # migration_command "rake db:migrate"
  environment "RAILS_ENV" => node['myusa']['rails_env'], "SECRET_TOKEN" => node['myusa']['secrets']['secret_key_base']
  shallow_clone false
  keep_releases 3
  action :deploy # or :rollback
  purge_before_symlink shared_dirs.values + shared_files.values
  create_dirs_before_symlink []
  symlink_before_migrate shared_files
  symlinks shared_dirs
  restart_command "touch tmp/restart.txt"
  before_symlink do
    # create shared directories
    shared_dirs.each_key do |dir|
      directory "#{deploy_to_dir}/shared/#{dir}" do
        owner node['myusa']['user']['username']
        group node['myusa']['user']['group']
        mode  00755
        recursive true
      end
    end
  end
end

directory "#{deploy_to_dir}/shared/config" do
  owner  node['myusa']['user']['username']
  recursive true
end


# Add upstart script
template "#{deploy_to_dir}/shared/config/env.sh" do
  source "env.sh.erb"
  variables(
    app_host:             node['myusa']['app_host'],
    sms_number:           node['myusa']['sms_number'],
    smtp_host:            node['myusa']['smtp_host'],
    smtp_port:            node['myusa']['smtp_port'],
    sender_email:         node['myusa']['sender_email'],
    elasticache_endpoint: node['myusa']['elasticache']['endpoint'],
    rails_env:            node['myusa']['rails_env']
  )
  owner  "root"
  group  "root"
  mode   "0644"
end

# set up templates for application secrets
template "#{deploy_to_dir}/shared/config/database.yml" do
  source "database.yml.erb"
  variables(
    rails_env: node['myusa']['rails_env'],
    database: node['myusa']['database']['name'],
    host: node['myusa']['database']['host'],
    port: node['myusa']['database']['port'],
    username: node['myusa']['database']['username'],
    password: node['myusa']['database']['password'],
    encryption_key: node['myusa']['secrets']['db_encrypt_key']
  )
end

template  "#{deploy_to_dir}/shared/config/secrets.yml" do
  source "secrets.yml.erb"
  variables(
    rails_env: node['myusa']['rails_env'],
    secret_key_base: node['myusa']['secrets']['secret_key_base'],
    devise_secret_key: node['myusa']['secrets']['devise_secret_key'],
    smtp_user: node['myusa']['secrets']['smtp_user'],
    smtp_pass: node['myusa']['secrets']['smtp_pass'],
    omniauth_google_app_id: node['myusa']['secrets']['omniauth_google_app_id'],
    omniauth_google_secret: node['myusa']['secrets']['omniauth_google_secret'],
    twilio_account_sid: node['myusa']['secrets']['twilio_account_sid'],
    twilio_auth_token: node['myusa']['secrets']['twilio_auth_token']
  )
end

template "#{deploy_to_dir}/shared/config/newrelic.yml" do
  source 'newrelic.yml.erb'
  variables(
    newrelic_license_key: node['myusa']['secrets']['newrelic_key']
  )
end

# set up rubies ...
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

rbenv_ruby node['myusa']['ruby_version'] do
  global true
end

rbenv_gem "bundler" do
  ruby_version node['myusa']['ruby_version']
end

rbenv_execute "run bundler" do
  ruby_version node['myusa']['ruby_version']
  command "bundle install --path=./.bundle --binstubs --deployment --without development test deploy"
  cwd deploy_to_dir + "/current"
  user node['myusa']['user']['username']
end

rbenv_execute "migrate db" do
  ruby_version node['myusa']['ruby_version']
  command "source config/env.sh && bundle exec rake db:migrate"
  cwd deploy_to_dir + "/current"
  environment "RAILS_ENV" => node['myusa']['rails_env']
  user node['myusa']['user']['username']
end

rbenv_execute "build assets" do
  ruby_version node['myusa']['ruby_version']
  command "source config/env.sh && bundle exec rake assets:precompile"
  cwd deploy_to_dir + "/current"
  environment "RAILS_ENV" => node['myusa']['rails_env']
  user node['myusa']['user']['username']
end

shipper_config "myusa" do
  repository node['myusa']['repo']
  environment node['myusa']['rails_env']
  app_path deploy_to_dir
  app_user node['myusa']['user']['username']
  github_key node['github_key']
  shared_files shared_files.merge(shared_dirs)
  before_symlink [
    "/opt/rbenv/shims/bundle --path=./.bundle --binstubs --deployment --without development test deploy RAILS_ENV=#{node['myusa']['rails_env']}",
    "source config/env.sh && /opt/rbenv/shims/bundle exec rake db:migrate RAILS_ENV=#{node['myusa']['rails_env']}",
    "source config/env.sh && /opt/rbenv/shims/bundle exec rake assets:precompile RAILS_ENV=#{node['myusa']['rails_env']}"
  ]
  after_symlink [
    "kill -HUP `status myusa | egrep -oi '([0-9]+)$'`"
  ]
end
