class Label < ApplicationRecord
  belongs_to :subject

  def text_color
    red, blue, green = RGB::Color.from_rgb_hex("##{color}").to_rgb
    # Magic numbers - see https://stackoverflow.com/a/3943023/2526265
    l = 0.2126 * red/255 + 0.7152 * green/255 + 0.0722 * blue/255;
    if (l + 0.05) / 0.05 > (1.05) / (l + 0.05)
      'black'
    else
      'white'
    end
  end
end
