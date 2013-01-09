Gem::Specification.new do |s| 
  s.name = 'monoriel'
  s.version = "0.1.0"
  s.platform = Gem::Platform::RUBY
  s.summary = "A rack based web framework forked from mini-train"
  s.description = "This is a super simplistic but useful web framework"
  s.files = `git ls-files`.split("\n").sort
  s.require_path = './lib'
  s.author = "Carlos Esquer"
  s.email = "carlosesquer@zinlim.com"
  s.homepage = "http://monoriel.zinlim.com"
  s.add_dependency(%q<tilt>, [">= 1.2.2"])
end
