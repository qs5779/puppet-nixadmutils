require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-syntax/tasks/puppet-syntax'

desc 'RuboCop checks'
task 'rubocop_checks' do
  RuboCop::RakeTask.new
end

desc "Run syntax, lint, and spec tests."
task :test => %i[
  rubocop_checks
  metadata_lint
  syntax
  lint
  spec
]
