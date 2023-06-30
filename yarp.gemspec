# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "yarp"
  spec.version = "0.5.0"
  spec.authors = ["Shopify"]
  spec.email = ["ruby@shopify.com"]

  spec.summary = "Yet Another Ruby Parser"
  spec.homepage = "https://github.com/ruby/yarp"
  spec.license = "MIT"

  spec.require_paths = ["lib"]
  spec.files = [
    "CODE_OF_CONDUCT.md",
    "config.yml",
    "configure.ac",
    "CONTRIBUTING.md",
    "Gemfile",
    "LICENSE.md",
    "Makefile.in",
    "Rakefile",
    "README.md",
    "yarp.gemspec",
    "ext/yarp/api_node.c",
    "include/yarp/ast.h",
    "java/org/yarp/Loader.java",
    "java/org/yarp/Nodes.java",
    "java/org/yarp/AbstractNodeVisitor.java",
    "lib/yarp/node.rb",
    "lib/yarp/serialize.rb",
    "src/node.c",
    "src/prettyprint.c",
    "src/serialize.c",
    "src/token_type.c"
  ] + Dir.glob([
    "docs/**/*",
    "ext/**/*",
    "include/**/*",
    "lib/**/*.rb",
    "src/**/*",
    "templates/**/*"
  ])

  spec.extensions = ["ext/yarp/extconf.rb"]
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
end
