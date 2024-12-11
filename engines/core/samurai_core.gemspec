$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "samurai/core/version" # Add samurai namespace

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "samurai_core"            # Rename core to samurai_core
  s.version     = Samurai::Core::VERSION    # Add namespace
  s.authors     = ["Rodrigo Fernandez"]     # Your name
  s.email       = ["rofaccess@gmail.com"]   # Your email
  s.homepage    = "https://github.com/rofaccess/SamuraiCRM"
  s.summary     = "Core features of SamuraiCRM."
  s.description = "Core features of SamuraiCRM."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.test_files = Dir[""]

  s.add_dependency "rails", "~> 4.2.0"

  s.add_development_dependency "sqlite3"
end
