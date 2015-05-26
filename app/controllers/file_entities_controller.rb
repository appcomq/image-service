class FileEntitiesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: :create

  def index
  end

  def new
  end

  def create
    # params 结构
    # { "bucket"=>"fushang318", 
    #   "key"=>"/i/yscPYbwk.jpeg", 
    #   "fsize"=>"3514", 
    #   "endUser"=>"5551b62b646562104b000000", 
    #   "image_rgb"=>"0xee4f60", 
    #   "origin_file_name"=>"icon200x200.jpeg",
    #   "mimeType" => "image/png",
    #   "image_width"=>"200",
    #   "image_height"=>"200",
    #   "avinfo_format" => "",
    #   "avinfo_total_bit_rate" => "",
    #   "avinfo_total_duration" => "",
    #   "avinfo_video_codec_name" => "",
    #   "avinfo_video_bit_rate"   => "",
    #   "avinfo_video_duration"   => "",
    #   "avinfo_height"           => "",
    #   "avinfo_width"            => "",
    #   "avinfo_audio_codec_name" => "",
    #   "avinfo_audio_bit_rate"   => "",
    #   "avinfo_audio_duration"   => ""
    # }
    file_entity = FileEntity.from_qiniu_callback_body(params)
    render json: {
      id: file_entity.id.to_s,
      kind: file_entity.kind,
      url: file_entity.url
    }
  end

  def uptoken
    put_policy = Qiniu::Auth::PutPolicy.new(ENV['QINIU_BUCKET'])
    put_policy.callback_url = File.join(ENV['QINIU_CALLBACK_HOST'], "/file_entities")
    put_policy.callback_body = 'bucket=$(bucket)&key=$(key)&fsize=$(fsize)&endUser=$(endUser)&image_rgb=$(imageAve.RGB)&origin_file_name=$(x:origin_file_name)&mimeType=$(mimeType)&image_width=$(imageInfo.width)&image_height=$(imageInfo.height)&avinfo_format=$(avinfo.format.format_name)&avinfo_total_bit_rate=$(avinfo.format.bit_rate)&avinfo_total_duration=$(avinfo.format.duration)&avinfo_video_codec_name=$(avinfo.video.codec_name)&avinfo_video_bit_rate=$(avinfo.video.bit_rate)&avinfo_video_duration=$(avinfo.video.duration)&avinfo_height=$(avinfo.video.height)&avinfo_width=$(avinfo.video.width)&avinfo_audio_codec_name=$(avinfo.audio.codec_name)&avinfo_audio_bit_rate=$(avinfo.audio.bit_rate)&avinfo_audio_duration=$(avinfo.audio.duration)'
    if !current_user.blank?
      put_policy.end_user = current_user.id.to_s
    end
    uptoken = Qiniu::Auth.generate_uptoken(put_policy)
    render json: {
      uptoken: uptoken
    }
  end
end