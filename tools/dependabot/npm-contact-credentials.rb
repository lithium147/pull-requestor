# designed to be inserted into the dependabot file: generic-update-script.rb
credentials << {
  "type" => "npm_registry",
  "registry" => "nexus.hsbc.com/nexus/content/repositories/Hsbc_npm",
  "token" => ENV["CONTACT_NEXUS_USER_TOKEN"]
}
