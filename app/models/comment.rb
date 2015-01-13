class Comment < ActiveRecord::Base
  belongs_to :article
  validates_presence_of :author, message: '請填寫推文者'
  validates_presence_of :article_id, message: '必須屬於一篇文章'
end
