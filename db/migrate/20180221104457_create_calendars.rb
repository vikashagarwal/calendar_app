class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.string :summary
      t.string :external_id

      t.timestamps null: false
    end
  end
end
