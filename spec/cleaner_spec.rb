require 'spec_helper'

module DatabaseRewinder
  describe Cleaner do
    describe '#strategy=' do
      before { @cleaner = described_class.new(only: ['foos'], except: 'bars') }

      context 'without options' do
        before { @cleaner.strategy = :truncation }

        it 'should keep instance variables' do
          expect(@cleaner.instance_variable_get(:@only)).to eq(['foos'])
          expect(@cleaner.instance_variable_get(:@except)).to eq(['bars'])
        end
      end

      context 'with options (an array or a string)' do
        before { @cleaner.strategy = :truncation, { only: ['bars'], except: 'bazs' } }

        it 'should overwrite instance variables' do
          expect(@cleaner.instance_variable_get(:@only)).to eq(['bars'])
          expect(@cleaner.instance_variable_get(:@except)).to eq(['bazs'])
        end
      end

      context 'with options (an empty array or nil)' do
        before { @cleaner.strategy = :truncation, { only: [], except: nil } }

        it 'should overwrite instance variables even if they are empty/nil' do
          expect(@cleaner.instance_variable_get(:@only)).to eq([])
          expect(@cleaner.instance_variable_get(:@except)).to eq([])
        end
      end
    end
  end
end
