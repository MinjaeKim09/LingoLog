require 'xcodeproj'

project_path = 'LingoLog.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Check if URL types exist
url_types = target.build_configurations.first.build_settings['INFOPLIST_KEY_CFBundleURLTypes'] || []

new_url_type = {
    'CFBundleTypeRole' => 'Editor',
    'CFBundleURLSchemes' => ['com.googleusercontent.apps.407621375642-u8fvah3g0ke22iroe55t1pa1k9fetqa7']
}

url_types << new_url_type
target.build_configurations.each do |config|
    config.build_settings['INFOPLIST_KEY_CFBundleURLTypes'] = url_types
end

project.save
puts "URL Scheme added."
