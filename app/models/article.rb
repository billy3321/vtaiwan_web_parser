class Article < ActiveRecord::Base
  has_many :comments

  before_save :parse_url

  def parse_url
    source_uri = URI.parse(self.source_url)
    if ['www.facebook.com'].include?(source_uri.try(:host))
      agent = Mechanize.new
      result = agent.get(self.source_url)
      parse_facebook_content(result.body)
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
    end
  end

  def parse_ptt_content(body)
    html = Nokogiri::HTML(body)
    self.title = html.at('meta[property="og:title"]')['content']
    info_section = html.css('div#main-container div#main-content.bbs-screen.bbs-content')[0]
    pushes = info_section.css('div.push')
    date_string = info_section.css('div.article-metaline span.article-meta-value')[2].text
    self.date = Time.parse(date_string)
    info_section.search('.//div').remove
    self.content = info_section.text.gsub("\n", '<br />')
    old_comment_author = ""
    puts self.comment_authors
    unless self.comment_authors.strip.empty?
      @comment_authors_list = self.comment_authors.split(',')
      @comment_authors_list.collect(&:strip)
    else
      @comment_authors_list = []
    end
    comment = nil
    self.comments.delete_all
    pushes.each do |p|
      puts p.text
      comment_author = p.css('span.push-userid')[0].text
      if @comment_authors_list.empty? or @comment_authors_list.include?(comment_author)
        if comment and comment.author == comment_author
          comment.content << "<br />" + p.css('span.push-content')[0].text
        else
          comment = self.comments.build
          comment.author = comment_author
          comment.content = p.css('span.push-content')[0].text
        end
      end
    end
  end


  def parse_facebook_content(body)
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
    begin
      errors.add(:base, 'source url error') unless HTTParty.get(self.youtube_url).code == 200
    rescue
      errors.add(:base, 'source url error')
    end
  end
end
