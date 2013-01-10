task :default => [:test]

desc "Run testing unit (default)"
task :test do
	ruby "test/monoriel-test.rb"
end

desc "Create distribution package"
task :build do
  sh "gem build monoriel.gemspec"
end
