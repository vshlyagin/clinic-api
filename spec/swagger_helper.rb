# frozen_string_literal: true

require 'rails_helper'
require "yaml"

RSpec.configure do |config|

  components = YAML.load_file(Rails.root.join("spec/utils/api/v1/components.yaml")).deep_symbolize_keys!

  config.openapi_root = Rails.root.join('swagger').to_s
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      servers: [{url: "http://localhost:3000"}],
      **components
    }
  }

  config.openapi_format = :yaml
end
