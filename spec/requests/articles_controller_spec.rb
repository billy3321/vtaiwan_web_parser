require "spec_helper"

describe "Article" do

  let(:user) { FactoryGirl.create(:user) }
  let(:article) { FactoryGirl.create(:ptt_article, user: user) }
  let(:new_article) do
    {
      :source_url => "https://www.ptt.cc/bbs/PublicIssue/M.1421063009.A.F39.html"
    }
  end

  describe "before login" do
    describe "#index with nothing" do
      it "success" do
        get "/articles/"
        expect(response).to be_success
      end
    end

    describe "#show" do
      it "success" do
        get "/articles/#{article.id}"
        expect(response).to be_success
      end
    end

    describe "#new" do
      it "redirect" do
        get "/articles/new"
        expect(response).to be_redirect
      end
    end

    describe "#edit" do
      it "redirect" do
        get "/articles/#{article.id}/edit"
        expect(response).to be_redirect
      end
    end

    describe "#create" do
      it "redirect" do
        post "/articles", :article => new_article
        expect(response).to be_redirect
      end
    end

    describe "#update" do
      it "redirect" do
        article
        update_data = { :source_url => "https://www.ptt.cc/bbs/Gossiping/M.1421070061.A.C38.html" }
        put "/articles/#{article.id}", :article => update_data
        expect(response).to be_redirect
      end
    end

    describe "#destroy" do
      it "redirect" do
        article
        expect {
          delete "/articles/#{article.id}"
        }.to change { Article.count }.by(0)
        expect(response).to be_redirect
      end
    end
  end
  describe "after login" do
    before { sign_in(user) }
    after { sign_out }

    describe "#new" do
      it "success" do
        get "/articles/new"
        expect(response).to be_success
      end
    end

    describe "#edit" do
      it "success" do
        get "/articles/#{article.id}/edit"
        expect(response).to be_success
      end
    end

    describe "#create" do
      it "success" do
        new_article[:user_id] = user.id
        expect {
          post "/articles", :article => new_article
        }.to change { Article.count }.by(1)
        expect(response).to be_redirect
      end
    end

    describe "#update" do
      it "success" do
        article
        update_data = { :source_url => "https://www.ptt.cc/bbs/Gossiping/M.1421070061.A.C38.html" }
        put "/articles/#{article.id}", :article => update_data
        expect(response).to be_redirect
        article.reload
        expect(article.source_url).to match(update_data[:source_url])
        expect(article.title).to match("連勝文6歲、4歲兒子當金控股東")
      end
    end

    describe "#destroy" do
      it "success" do
        article
        expect {
          delete "/articles/#{article.id}"
        }.to change { Article.count }.by(-1)
        expect(response).to be_redirect
      end
    end
  end
end