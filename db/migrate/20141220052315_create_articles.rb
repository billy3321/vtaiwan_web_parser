class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.text :content
      t.string :source_url
      t.string :comment_authors
      t.datetime  :date

      t.timestamps null: false
    end
  end
end
