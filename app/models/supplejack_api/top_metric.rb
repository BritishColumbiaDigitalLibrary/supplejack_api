# frozen_string_literal: true

##
# The purpose of this metric is to store the top 200 records for page_views,
# user_set_views, user_story_views, added_to_user_sets, source_clickthroughs,
# appeared_in_searches, added_to_user_sets for each day.
#
# The results are stored as a hash of record_id => metric count
#

module SupplejackApi
  # app/models/supplejack_api/top_metric.rb
  class TopMetric
    include Mongoid::Document

    METRICS = %i[
      page_views
      user_set_views
      user_story_views
      added_to_user_sets
      source_clickthroughs
      appeared_in_searches
      added_to_user_stories
    ].freeze

    field :d, as: :date,    type: Date, default: Time.current.utc
    field :m, as: :metric,  type: String
    field :r, as: :results, type: Hash

    validates :date, presence: true
    validates :metric, presence: true
    validates :metric, uniqueness: { scope: :date }

    def self.spawn
      return unless SupplejackApi.config.log_metrics == true
      dates = SupplejackApi::RecordMetric.all.map(&:date).uniq

      dates.each do |date|
        METRICS.each do |metric|
          results = results(date, metric).each_with_object({}) do |record, hash|
            hash[record.record_id.to_s] = record.send(metric)
          end

          metric = find_or_create_by(
            date: date,
            metric: metric
          )

          if metric.results.blank?
            metric.update(results: results)
          else
            merged_results = metric.results.merge(results) { |_key, a, b| a + b }
            merged_results = merged_results.sort_by { |_k, v| -v }.first(200).to_h

            metric.update(results: merged_results)
          end
        end
      end
    end

    def self.results(date, metric)
      SupplejackApi::RecordMetric.where(date: date).order_by(metric => 'desc').limit(200)
    end
  end
end
