FactoryGirl.define do
  factory :comment do
    sequence(:author)  { |n| "Commenter #{n}" }
    sequence(:content) { |n| "comment_#{n} content"}
    article{ FactoryGirl.create(:article) }
  end
end