source 'https://rubygems.org'

group :lint do
  gem 'rubocop'
  gem 'foodcritic', git: 'https://github.com/acrmp/foodcritic'
end

group :kitchen_common do
  gem 'test-kitchen', '~> 1.4'
end

group :kitchen_vagrant do
  gem 'kitchen-vagrant', '~> 0.17'
end

group :kitchen_cloud do
  gem 'kitchen-openstack', '~> 1.8'
end

group :unit do
  gem 'berkshelf'
  gem 'chefspec'
end

gem 'chef', '~> 12.5.0'
gem 'berkshelf', '~> 2.0.10'

group :test do
  gem 'foodcritic', '~> 3.0'
  gem 'rubocop', '~> 0.23.0'
end

group :integration do
  gem 'serverspec'
end
