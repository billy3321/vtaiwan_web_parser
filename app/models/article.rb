class Article < ActiveRecord::Base
  has_many :comments, dependent: :destroy
  belongs_to :user
  validates_presence_of :source_url, message: '請填寫網址'

  before_save :parse_comment_authors, :parse_url


  def get_app_fb_graph_api
    # 取得 FB app access token
    @fb_app_graph_api ||= Koala::Facebook::API.new([
      Setting.facebook_auth_key.app_id,
      Setting.facebook_auth_key.app_secret].join('|'))
  end


  def get_user_fb_graph_api
    # 取得 FB 使用者 access token
    self.user.refresh_facebook_token
    @fb_user_graph_api = Koala::Facebook::API.new(self.user.access_token,  Setting.facebook_auth_key.app_secret)
  end


  def parse_comment_authors
    # 解析comment_authors成為array，方便後續存取
    if self.comment_authors and not self.comment_authors.strip.empty?
      @comment_authors_list = self.comment_authors.split(',')
      @comment_authors_list.collect(&:strip)
    else
      @comment_authors_list = []
    end
  end


  def parse_url
    # 解析貼上的網址
    source_uri = URI.parse(self.source_url)
    # Facebook分為照片及網址，這兩個解析方式不一樣。另外，FB網誌暫時無法解析（API不支援）
    if ['www.facebook.com'].include?(source_uri.try(:host))
      path_elements = source_uri.path.split('/')
      if path_elements[1] == 'photo.php'
        photo_id = CGI::parse(source_uri.query)['fbid'].first
        parse_fb_photo(photo_id)
      elsif path_elements[1] == 'permalink.php'
        link_id = CGI::parse(source_uri.query)['story_fbid'].first
        parse_fb_link(link_id)
      elsif path_elements[2] == 'photos'
        photo_id = path_elements.last
        parse_fb_photo(photo_id)
      elsif path_elements[2] == 'posts'
        fb_user_name = path_elements[1]
        fb2_graph_api = Koala::Facebook::API.new
        fb_user_id = fb2_graph_api.get_object(fb_user_name)['id']
        post_id = [fb_user_id, path_elements.last].join('_')
        parse_fb_post(post_id)
      else
        return false
      end
    # PTT 除了八卦版以外都是直接抓，八卦版需支援cookie，點選十八歲確認按鈕後才可解析。
    elsif ['www.ptt.cc'].include?(source_uri.try(:host))
      if source_uri.path.include?('Gossiping')
        agent = Mechanize.new
        result = agent.post('https://www.ptt.cc/ask/over18', {from: source_uri.path, yes: 'yes'})
        parse_ptt_content(result.body)
      else
        agent = Mechanize.new
        result = agent.get(self.source_url)
        parse_ptt_content(result.body)
      end
    # 除此之外不儲存
    else
      return false
    end
  end

  def parse_fb_photo(photo_id)
    # 解析 FB 照片內容
    fb_graph_api = get_app_fb_graph_api
    photo_content = fb_graph_api.get_object(photo_id)
    self.image = photo_content["source"]
    self.title = photo_content["name"][0..20]
    self.content = photo_content["name"].gsub("\n", "<br />")
    self.source_url = photo_content["link"]
    img_width = 0
    photo_content["images"].each do | img |
      if img["width"] > img_width
        img_width = img["width"]
        self.image = img["source"]
      end
    end
    comment_id = photo_id + '/comments'
    comments = fb_graph_api.get_object(comment_id, {limit: 100000})
    self.comments.delete_all
    comments.each do |c|
      comment_author = c["from"]["name"]
      if @comment_authors_list.empty? or @comment_authors_list.include?(comment_author)
        comment = self.comments.build
        comment.author = comment_author
        comment.content = c["message"].gsub("\n", "<br />")
        comment.like = c["like_count"]
      end
    end
  end


  def parse_fb_post(post_id)
    # 解析 FB 貼文內容
    fb_graph_api = get_user_fb_graph_api
    post_content = fb_graph_api.get_object(post_id)
    if post_content["name"]
      self.title = post_content["name"]
    else
      self.title = post_content["message"][0..20]
    end
    self.content = post_content["message"].gsub("\n", "<br />")
    self.image = post_content["picture"] if post_content["picture"]
    self.link = post_content["link"] if post_content["link"]
    comment_id = post_id + '/comments'
    comments = fb_graph_api.get_object(comment_id, {limit: 100000})
    self.comments.delete_all
    comments.each do |c|
      comment_author = c["from"]["name"]
      if @comment_authors_list.empty? or @comment_authors_list.include?(comment_author)
        comment = self.comments.build
        comment.author = comment_author
        comment.content = c["message"].gsub("\n", "<br />")
        comment.like = c["like_count"]
      end
    end
  end

  def parse_fb_link(link_id)
    # 解析 FB 分享連結內容
    fb_graph_api = get_user_fb_graph_api
    link_content = fb_graph_api.get_object(link_id)
    self.title = link_content["message"]["name"]
    self.content = link_content["message"].gsub("\n", "<br />")
    self.link = link_content["link"]
    self.image = link_content["picture"]
    comment_id = link_id + '/comments'
    comments = fb_graph_api.get_object(comment_id, {limit: 100000})
    self.comments.delete_all
    comments.each do |c|
      comment_author = c["from"]["name"]
      if @comment_authors_list.empty? or @comment_authors_list.include?(comment_author)
        comment = self.comments.build
        comment.author = comment_author
        comment.content = c["message"].gsub("\n", "<br />")
        comment.like = c["like_count"]
      end
    end
  end


  def parse_ptt_content(body)
    # 解析 PTT 網頁
    html = Nokogiri::HTML(body)
    self.title = html.at('meta[property="og:title"]')['content']
    info_section = html.css('div#main-container div#main-content.bbs-screen.bbs-content')[0]
    pushes = info_section.css('div.push')
    date_string = info_section.css('div.article-metaline span.article-meta-value')[2].text
    self.date = Time.parse(date_string)
    info_section.search('.//div').remove
    self.content = info_section.text.gsub("\n", '<br />')
    old_comment_author = ""

    comment = nil
    self.comments.delete_all
    pushes.each do |p|
      comment_author = p.css('span.push-userid')[0].text
      if @comment_authors_list.empty? or @comment_authors_list.include?(comment_author)
        if comment and comment.author == comment_author
          comment.content << "<br />" + p.css('span.push-content')[0].text[2..-1]
        else
          comment = self.comments.build
          comment.author = comment_author
          comment.content = p.css('span.push-content')[0].text[2..-1]
        end
      end
    end
  end


  def parse_facebook_content(body)
    # 用 Nokogiri 解析 FB 內容（暫時不會用到）
    html = Nokogiri::HTML(body)
    return html
    self.title = html.title
    content = html.css('div.userContent')[0].text
    self.content = content.gsub("\n", '<br />')
    comments = html.css('li.UFIRow.UFIComment.display.UFIComponent')
    comments.each do |c|
      comment = self.comments.build
      comment.author = c.css('a.UFICommentActorName').text
      comment.content = c.css('span.UFICommentBody').text
    end
  end

  private

  def check_source_url
    # 確認網址可用
    begin
      errors.add(:base, 'source url error') unless HTTParty.get(self.youtube_url).code == 200
    rescue
      errors.add(:base, 'source url error')
    end
  end
end
