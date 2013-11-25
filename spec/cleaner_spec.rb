require 'spec_helper'

module DatabaseRewinder

describe Cleaner do
  describe '#strategy=' do
    before { @cleaner = described_class.new }

    context 'when only strategy is given' do
      before { @cleaner.strategy = :truncation }

      it 'should ignore strategy' do
        expect(@cleaner.instance_variable_get(:@only)).to eq([])
        expect(@cleaner.instance_variable_get(:@except)).to eq([])
      end
    end

    context 'when only option is given' do
      before { @cleaner.strategy = :truncation, { only: ['foos'] } }

      it 'should set only option' do
        expect(@cleaner.instance_variable_get(:@only)).to eq(['foos'])
        expect(@cleaner.instance_variable_get(:@except)).to eq([])
      end
    end

    context 'when except option is given' do
      before { @cleaner.strategy = :truncation, { except: ['foos'] } }

      it 'should set only option' do
        expect(@cleaner.instance_variable_get(:@only)).to eq([])
        expect(@cleaner.instance_variable_get(:@except)).to eq(['foos'])
      end
    end

    context 'when only and except option are given' do
      before { @cleaner.strategy = :truncation, { only: ['foos'], except: ['bars'] } }

      it 'should set only option' do
        expect(@cleaner.instance_variable_get(:@only)).to eq(['foos'])
        expect(@cleaner.instance_variable_get(:@except)).to eq(['bars'])
      end
    end
  end
end

end # module DatabaseRewinder
