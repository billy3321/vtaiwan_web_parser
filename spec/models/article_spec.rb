require "rails_helper"

describe Article do
  let(:article) {FactoryGirl.create(:article)}

  it "#ptt_creat_success" do
    expect {
      FactoryGirl.create :ptt_article
    }.to change { Article.count }.by(1)
  end

  it "#gossiping_ptt_creat_success" do
    expect {
      FactoryGirl.create :gossiping_ptt_article
    }.to change { Article.count }.by(1)
  end

  it "update_gossiping_ptt_content_success" do
    article = Article.new
    article.source_url = "https://www.ptt.cc/bbs/Gossiping/M.1421070061.A.C38.html"
    article.save
    expect(article.title).to match("連勝文6歲、4歲兒子當金控股東")
  end

  it "update_ptt_content_success" do
    article = Article.new
    article.source_url = "https://www.ptt.cc/bbs/PublicIssue/M.1421063009.A.F39.html"
    article.save
    expect(article.title).to match("剝蕉案")
  end

  it "filter_ptt_comments_success" do
    article = Article.new
    article.source_url = "https://www.ptt.cc/bbs/PublicIssue/M.1421063009.A.F39.html"
    article.comment_authors = "aa789,yudi1991"
    article.save
    expect(article.comments.length).to eq(2)
    comment_authors = article.comment_authors.split(',')
    article.comments.each do |c|
      expect(comment_authors).to include(c.author)
    end
  end
end
