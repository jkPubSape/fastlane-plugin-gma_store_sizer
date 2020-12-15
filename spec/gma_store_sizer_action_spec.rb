describe Fastlane::Actions::GmaStoreSizerAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The gma_store_sizer plugin is working!")

      Fastlane::Actions::GmaStoreSizerAction.run(nil)
    end
  end
end
