if Rails.env.development?
  require "rubycritic/rake_task"

  RubyCritic::RakeTask.new do |task|
    # Name of RubyCritic task. Defaults to :rubycritic.

    # Glob pattern to match source files. Defaults to FileList['.'].
    task.paths   = FileList['app/**/*.rb', 'lib/**/*.rb', 'vendor/**/*.rb', 'config/**/*.rb']

    # Defaults to false
    task.verbose = true
  end
end
