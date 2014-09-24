class Account < ActiveRecord::Base
  belongs_to :user

  validates_numericality_of :fund, :frozen_fund, :greater_than_or_equal_to => 0
  validates_presence_of :w_first_name, :w_last_name, :w_country_id,
    :if => Proc.new{|a| a.type == 'west'}

  attr_accessor :type

end
