class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer :article_id
      t.string :author
      t.text :content
      t.integer :likes

      t.timestamps null: false
    end
  end
end
