FactoryGirl.define do
  factory :article do
  end

  factory :ptt_article, parent: :article do
    source_url "https://www.ptt.cc/bbs/PublicIssue/M.1421063009.A.F39.html"
  end

  factory :gossiping_ptt_article, parent: :article do
    source_url "https://www.ptt.cc/bbs/Gossiping/M.1421070061.A.C38.html"
  end
end