class Article < ActiveRecord::Base
  has_many :comments

  before_save :parse_url

  def parse_url
    source_uri = URI.parse(self.source_url)
    if ['www.facebook.com'].include?(source_uri.try(:host))
      parse_facebook_content
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
    content = info_section.text.split('※ 發信站: 批踢踢實業坊(ptt.cc), 來自:')[0]
    self.content = content.gsub("\n", '<br />')
    old_comment_author = ""
    puts self.comment_authors
    if self.comment_authors
      comment_authors = self.comment_authors.split(',')
      comment_authors.collect(&:strip)
      puts comment_authors
    else
      comment_authors = []
    end
    comment = nil
    pushes.each do |p|
      puts p.text
      comment_author = p.css('span.push-userid')[0].text
      if comment_authors.empty? or comment_authors.include?(comment_author)
        comment = self.comments.build
        comment.author = comment_author
        comment.content = p.css('span.push-content')[0].text
      end
    end
  end


  def self.parse_facebook_content
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
