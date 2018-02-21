# == Schema Information
#
# Table name: calendars
#
#  id          :integer          not null, primary key
#  summary     :string(255)
#  external_id :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Calendar < ActiveRecord::Base
end
