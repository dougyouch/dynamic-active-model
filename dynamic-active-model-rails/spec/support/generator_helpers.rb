# frozen_string_literal: true

require 'stringio'
require 'tmpdir'

# Runs a generator against a temp directory, raising Thor::Error instead of printing it
module GeneratorHelpers
  def run_generator(generator, args)
    original = $stdout
    $stdout = StringIO.new
    generator.start(args, destination_root: destination, debug: true)
    $stdout.string
  ensure
    $stdout = original
  end

  def destination
    @destination ||= Dir.mktmpdir
  end

  def generated(path)
    File.read(File.join(destination, path))
  end

  def generated?(path)
    File.exist?(File.join(destination, path))
  end

  def valid_ruby?(source)
    RubyVM::InstructionSequence.compile(source)
    true
  end
end

RSpec.configure do |config|
  config.include GeneratorHelpers, type: :generator
  config.after(type: :generator) { FileUtils.rm_rf(destination) }
end
