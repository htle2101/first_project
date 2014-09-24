# encoding: utf-8
class Role < ActiveRecord::Base
  # TODO: This works around a bug in rails habtm with namespaces.
  has_and_belongs_to_many :users, :join_table => ::RolesUsers.table_name

  before_validation :camelize_title
  validates :title, :uniqueness => true

  class << self

    def method_missing(name, *argv, &block)
      if name.to_s =~ /(.*)s$/ && Role.where(:title => $1).present? # cannot use exists? because it call method_missing internal
        self.class.send :define_method, name do
          User.joins(:roles).where("roles.title = ?", $1)
        end.call
      else
        super
      end
    end

    def respond_to?(name, include_private = false)
      if name.to_s =~ /(.*)s$/ && Role.where(:title => $1).present? # cannot use exists? because it call method_missing internal

        true
      else
        super
      end
    end

  end # end of class << self

  def camelize_title(role_title = self.title)
    self.title = role_title.to_s.delete(" ").camelize
  end

  def self.[](title)
    find_or_create_by_title(title.to_s.camelize)
  end
end
