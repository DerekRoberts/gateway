class Query
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :map, :type => String
  field :reduce, :type => String
  field :filter, :type => Hash
  field :status, :type => Symbol
  field :delayed_job_id
  
  embeds_many :job_logs
  has_one :result
  
  validates_presence_of :map
  validates_presence_of :reduce
  
  def status_change(new_status, message)
    self.status = new_status
    job_logs << JobLog.new(:message => message)
    save!
  end
  
  def has_been_updated?
    created_at != updated_at
  end
  
  def filter_from_json_string(json_string)
    if json_string.present?
      self.filter = ActiveSupport::JSON.decode(json_string.strip)
    end
  end
  
  def job
    dj = QueryJob.submit(self.map, self.reduce, self.filter, self.id)
    self.delayed_job_id = dj.id
    save!
    dj
  end
  
  def self.last_query_update
    latest_query = desc(:updated_at).first
    if latest_query
      latest_query.updated_at
    else
      Time.new(2011, 8, 12) # hardcode to old date if there are no queries in the system
    end
  end
end
