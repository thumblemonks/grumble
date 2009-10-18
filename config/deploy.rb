set :application, "grumble"
set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache
set :git_enable_submodules, 1
set :repository,  "mercurial@aplikorecruit.com:git/grumble.git"

set :deploy_to, "/var/app/#{application}"
set :user, "deploy"
set :use_sudo, false
# set :runner, :app

role :app, "grumble.annealer.org"
role :web, "grumble.annealer.org"
role :db,  "grumble.annealer.org", :primary => true

task :after_update_code, :roles => :app, :except => {:no_symlink => true} do 
  run <<-CMD 
cd #{release_path} && 
ln -nfs #{shared_path}/config/dblogin.yml #{release_path}/config/dblogin.yml
CMD
end

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts
namespace :deploy do
  task(:start) {}
  task(:stop) {}
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt}"
    puts "love."
  end
end

# namespace :passenger do
#   desc "Restart Application"
#   task :restart do
#     run "touch #{current_path}/tmp/restart.txt"
#     puts "love."
#   end
# end

# after :deploy, "passenger:restart"
set :cold_deploy, false
before("deploy:cold") { set :cold_deploy, true }

after "deploy:setup" do
  run "mkdir #{shared_path}/config"
end

before "deploy:migrate" do
  next unless cold_deploy
  run "cp #{current_path}/config/dblogin.yml.example #{shared_path}/config/dblogin.yml"
  puts "\n---\nShared DB Config file has been set up at #{shared_path}/config/dblogin.yml - edit and hit enter to continue."
  nil while $stdin.gets != "\n"
end
