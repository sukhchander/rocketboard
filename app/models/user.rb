class User < ActiveRecord::Base

  enum role: [:user, :vip, :admin]

  after_initialize :set_default_role, if: :new_record?

  devise :database_authenticatable, :registerable, :confirmable, :recoverable,
          :rememberable, :trackable, :validatable

  include Gravtastic
  gravtastic

  has_many :orders

  def performance_data(date_range=nil)
    window = date_range.present? ? date_range : DashboardHelper.determine_window
    query = Api::V1::Order.complete.where(end_at: window).where(user: self).includes(:user)
    query.joins(:user).group(:user_id)
    filter = "user_id, SUM(units) AS total_units, COUNT(id) as y_val, to_char(date(end_at), 'YYYY-MM') AS x_val, SUM(total) AS amount"
    query.select(filter).group([:user_id, :units, :x_val]).order(:user_id)
  end

  def performance_amount
    DashboardHelper.format_currency(self.performance_data.map(&:amount).sum)
  end

  def performance_units
    DashboardHelper.format_unit(self.performance_data.map(&:total_units).sum)
  end

  def self.performance(user_id=nil, date_range=nil, display=false, xhr=false)
    self.performance_display(user_id, date_range, display, xhr)
  end

  def self.performance_data(user_id=nil, date_range=nil)
    window = date_range.present? ? date_range : DashboardHelper.determine_window
    query = Api::V1::Order.complete.where(end_at: window).where(user_id: user_id).includes(:user)
    filter = "user_id, COUNT(id) as y_val, to_char(date(end_at), 'YYYY-MM') AS x_val, SUM(total) AS z_val"
    query.select(filter).group([:user_id, :x_val]).order(:user_id).sort_by(&:x_val)
  end

  def self.performance_display(user_id=nil, date_range=nil, display=false, xhr=false)
    records = self.performance_data(user_id, date_range)
    {
      xAxis: records.collect(&:x_val),
      yAxis: records.collect(&:y_val),
      zAxis: records.collect(&:z_val)
    }
  end


private

  def set_default_role
    self.role ||= :user
  end

end