class Reply < ActiveRecord::Base
  belongs_to :user
  belongs_to :message
  validates :content, :presence => true

  delegate :username, :to => :user, :prefix => true
end
