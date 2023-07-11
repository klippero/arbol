class AlbumController < ApplicationController
  def photos
    if params[:p]
      @p = Person.find(params[:p].to_i)
      @photos = @p.photos.sort_by(&:date)
      @f = @p.childrenof
    else
      @p = nil
      @photos = Photo.all.sort_by(&:date)
    end
  end
end
