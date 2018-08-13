class Label < ApplicationRecord
  belongs_to :subject

  def text_color
    red, blue, green = RGB::Color.from_rgb_hex("##{color}").to_rgb
    # Magic numbers - see https://stackoverflow.com/a/3943023/2526265
    if (red*0.299 + green*0.587 + blue*0.114) > 186
      'black'
    else
      'white'
    end
  end
end
