# frozen_string_literal: true

RSpec.describe DynamicActiveModel::Rails::AutoloaderSetup do
  subject(:setup) { described_class.new(autoloaders, definition, Pathname.new('/app')) }

  let(:inflector) { Class.new { def inflect(overrides) = (@overrides ||= {}).merge!(overrides) }.new }
  let(:main) { Struct.new(:inflector, :ignored) { def ignore(glob) = ignored << glob }.new(inflector, []) }
  let(:autoloaders) { Struct.new(:main).new(main) }
  let(:definition) { DynamicActiveModel::Rails::DatabaseDefinition.new(:cars, **options) }
  let(:options) { {} }

  before { setup.apply }

  it 'maps the folder to the namespace in the autoloader inflector' do
    expect(inflector.instance_variable_get(:@overrides)).to eq('cars_db' => 'CarsDB')
  end

  it 'ignores extension files in the extensions folder' do
    expect(main.ignored).to eq(['/app/app/models/cars_db/*.ext.rb'])
  end

  context 'with a custom extensions path and suffix' do
    let(:options) { { extensions_path: 'lib/cars', extensions_suffix: '.model.rb' } }

    it 'ignores those files instead' do
      expect(main.ignored).to eq(['/app/lib/cars/*.model.rb'])
    end
  end
end
