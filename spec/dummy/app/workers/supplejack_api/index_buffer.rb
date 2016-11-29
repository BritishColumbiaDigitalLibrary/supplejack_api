# The majority of the Supplejack API code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

# Handles the logic for storing and retreiving record_ids from Redis
# which should be indexed or removed from Solr.

module SupplejackApi
  class IndexBuffer

    def pop_record_ids(method=:index, num=1000)
      ids = []

      Sidekiq.redis do |conn|
        while ids.count < num and id = conn.lpop("#{method}_buffer_record_ids")
          ids << id
        end
      end

      ids
    end

    def records_to_index
      @records_to_index ||= SupplejackApi::Record.where(:id.in => self.pop_record_ids(:index)).to_a
      @records_to_index.keep_if {|r| r.should_index? }
      @records_to_index
    end

    def records_to_remove
      @records_to_remove ||= SupplejackApi::Record.where(:id.in => self.pop_record_ids(:remove)).to_a
      @records_to_remove.delete_if {|r| r.should_index?}
      @records_to_remove
    end

    [:index, :remove].each do |method|
      define_method("#{method}_record_ids=") do |ids|
        Sidekiq.redis do |conn|
          ids.each do |id|
            conn.rpush("#{method}_buffer_record_ids", id)
          end
        end
      end

      define_method("#{method}_record_ids_count") do
        Sidekiq.redis do |conn|
          conn.llen("#{method}_buffer_record_ids")
        end
      end
    end
  end
end
