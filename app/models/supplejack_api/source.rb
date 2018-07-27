# frozen_string_literal: true

module SupplejackApi
  class Source
    include Mongoid::Document

    store_in collection: 'sources', client: 'strong'

    field :name,                 type: String
    field :source_id,            type: String
    field :status,               type: String, default: 'active'
    field :status_updated_by,    type: String
    field :status_updated_at,    type: DateTime

    belongs_to :partner, class_name: 'SupplejackApi::Partner'

    validates :name, presence: true

    scope :suppressed,  -> { where(status: 'suppressed') }

    # Its not completely random. Its not effiient to run .sample on large collections.
    # Fetches 4 random records from first 100 and last 100
    def random_records(limit)

      # db = Mongoid::Clients.default
      # collection = db[:records]
      # collection.aggregate([ { '$sample': { size: 10 }}]).to_a

      # .where('fragments.source_id' => source_id, status: 'active')



      Record.aggregates([{ '$match': { source_id: source_id, status: 'active' }, '$sample': { size: limit } }])

      Record.where('fragments.source_id' => source_id, status: 'active').aggregates([{ '$sample': { size: limit } }])


      ## Attempted queries  Record.aggregates([ { '$match': { 'fragments.source_id' => 'nlnzcat_alma', status: 'active' }}])
      # Record.where('fragments.source_id' => 'nlnzcat_alma', status: 'active').aggregates([ { $sample => { size: 100 }}]) =>  {"count"=>0, "sum"=>nil, "avg"=>nil, "min"=>nil, "max"=>nil}


      # records = Record.where('fragments.source_id' => source_id, :status => 'active')
      #
      # first_hundred = records.sort('fragments.syndication_date' => 1).limit(100).to_a
      # last_hundred = records.sort('fragments.syndication_date' => -1).limit(100).to_a
      #
      # (first_hundred | last_hundred).sample(limit)
    end
  end
end
