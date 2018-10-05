require 'emoji'

module EmojiHelper
  def emojify(content)
    html_escape_once(content).to_str.gsub(/:([\w+-]+):/) do |match|
      if (emoji = Emoji.find_by_alias($1))
        %(<img alt="#$1" src="#{image_path("emoji/#{emoji.image_filename}")}" style="vertical-align:middle" class='emoji'/>)
      else
        match
      end
    end.html_safe if content.present?
  end
end
