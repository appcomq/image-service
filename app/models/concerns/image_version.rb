 class ImageVersion
  attr_reader :name, :url
  def initialize(file_entity, image_size)
    @image = file_entity
    @image_size = image_size
    @name = _init_name
    @url  = _init_url
  end
  
  def _init_name
    return "原始图片" if @image_size.blank?
    @image_size.name
  end

  def _init_url
    return @image.url if @image_size.blank?
    return _get_oss_url if @image.is_oss?
    _get_qiniu_url
  end

  # 获取 aliyun oss 自定义尺寸图片url
  def _get_oss_url
    case @image_size.style
    when 'width_height'
      "#{@image.url}@#{@image_size.width}w_#{@image_size.height}h_1e_1c#{@image.ext}"
    when 'width'
      "#{@image.url}@#{@image_size.width}w#{@image.ext}"
    when 'height'
      "#{@image.url}@#{@image_size.height}h#{@image.ext}"
    end
  end

  # 获取 qiniu 云存储 自定义尺寸图片url
  def _get_qiniu_url
    url = @image.url
    width = @image_size.width
    height = @image_size.height

    case @image_size.style
    when 'width_height'
      "#{url}?imageMogr2/thumbnail/!#{width}x#{height}r/gravity/Center/crop/#{width}x#{height}"
    when 'width'
      "#{url}?imageMogr2/thumbnail/#{width}x"
    when 'height'
      "#{url}?imageMogr2/thumbnail/x#{height}"
    end
  end

  def to_html
    "<img src='#{@url}' />"
  end

  def to_md
    "![](#{@url})"
  end

  def ==(another)
    self.name == another.try(:name) and 
      self.url == another.try(:url)
  end
end