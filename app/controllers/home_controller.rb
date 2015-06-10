class HomeController < ApplicationController
  def index
    return render "/home/login" if !user_signed_in?

    per_page = 20
    if params[:less_than_id]
      @images = current_user.file_entities.images
        .is_qiniu
        .where(:id.lt => params[:less_than_id])
        .page(1).per(per_page)
    else
      @images = current_user.file_entities.images
        .is_qiniu
        .page(1).per(per_page)
    end
    render "/home/index"
  end
end