# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::Redis::BackfillProjectPipelineStatusTtl,
  :clean_gitlab_redis_cache, feature_category: :redis do
  let(:redis) { ::Redis.new(::Gitlab::Redis::Cache.params) }
  let(:keys) { ["cache:gitlab:project:1:pipeline_status", "cache:gitlab:project:2:pipeline_status"] }
  let(:invalid_keys) { ["cache:gitlab:project:pipeline_status:1", "cache:gitlab:project:pipeline_status:2"] }

  subject { described_class.new }

  before do
    (keys + invalid_keys).each { |key| redis.set(key, 1) }
  end

  describe '#perform' do
    it 'sets a ttl on given keys' do
      subject.perform(keys)

      keys.each do |k|
        expect(redis.ttl(k)).to be > 0
      end
    end
  end

  describe '#scan_match_pattern' do
    it "finds all the required keys only" do
      expect(redis.scan('0').second).to match_array(keys + invalid_keys)
      expect(subject.redis.scan_each(match: subject.scan_match_pattern).to_a).to contain_exactly(*keys)
    end
  end

  describe '#redis' do
    it { expect(subject.redis.inspect).to eq(redis.inspect) }
  end
end
