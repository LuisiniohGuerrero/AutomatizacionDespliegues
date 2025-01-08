require 'chefspec'
require 'chefspec/policyfile'

# Configuración para la versión de Chef que estás usando
RSpec.configure do |config|
  config.platform = 'ubuntu'
  config.version = '20.04'
end