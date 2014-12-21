class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.integer :user_id
      t.string :title
      t.text :content
      t.string :image
      t.string :source_url
      t.string :comment_authors
      t.datetime  :date

      t.timestamps null: false
    end
  end
end
