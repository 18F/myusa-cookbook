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
  "config/memcached.yml" => "config/memcached.yml",
  "config/newrelic.yml" => "config/newrelic.yml",
  "config/secrets.yml" => "config/secrets.yml",
  "config/#{node['myusa']['rails_env']}.rb" => "config/environments/#{node['myusa']['rails_env']}.rb"
}

directory deploy_to_dir do
  owner  node['myusa']['user']['username']
  recursive true
end

directory "#{deploy_to_dir}/shared/config" do
  owner  node['myusa']['user']['username']
  recursive true
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

shared_dirs.each do |dir, links|
  directory "#{deploy_to_dir}/shared/#{dir}" do
    owner  node['myusa']['user']['username']
  end
end

# set up environment.rb file
#
# TODO: Kill this block and environment.rb.erb once the
#       myusa "environment-config" branch merges to master
template "#{deploy_to_dir}/shared/config/#{node['myusa']['rails_env']}.rb" do
  source "environment.rb.erb"
  variables(
    app_host: node['myusa']['app_host'],
    elasticache_endpoint: node['myusa']['elasticache']['endpoint']
  )
end

template  "#{deploy_to_dir}/shared/config/secrets.yml" do
  source "secrets.yml.erb"
  variables(
    rails_env: node['myusa']['rails_env'],
    secret_key_base: node['myusa']['secrets']['secret_key_base'],
    devise_secret_key: node['myusa']['secrets']['devise_secret_key'],
    aws_ses_username: node['myusa']['secrets']['aws_ses_username'],
    aws_ses_password: node['myusa']['secrets']['aws_ses_password'],
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

# Shipper will start and run the last deployment available for the environment
# If no deployment is found it will NOT deploy
shipper_config "myusa" do
  repository node['myusa']['repo']
  environment node['environment']
  app_path deploy_to_dir
  app_user node['myusa']['user']['username']
  github_key node['github_key']
  shared_files shared_files.merge(shared_dirs)
  before_symlink [
    "/opt/rbenv/shims/bundle --path=./.bundle --binstubs --deployment --without development test deploy RAILS_ENV=#{node['myusa']['rails_env']}",
    "/opt/rbenv/shims/bundle exec rake db:migrate RAILS_ENV=#{node['myusa']['rails_env']}",
    "/opt/rbenv/shims/bundle exec rake assets:precompile RAILS_ENV=#{node['myusa']['rails_env']}"
  ]
  after_symlink [
    "kill -HUP `status myusa | egrep -oi '([0-9]+)$'`"
  ]
end
