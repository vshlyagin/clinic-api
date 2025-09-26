# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "*"

#     resource "*",
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head],
#       expose: ["Access-Control-Allow-Origin", "Access-Control-Allow-Headers", "Access-Control-Allow-Methods"],
#       max_age: 600
#   end
# end