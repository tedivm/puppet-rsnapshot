require 'spec_helper'
describe 'rsnapshot' do

  context 'with defaults for all parameters' do
    it { should contain_class('rsnapshot') }
  end
end
