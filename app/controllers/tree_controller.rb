class TreeController < ApplicationController

  before_action :authenticate_user!

  def familia
    @f = Family.find(params[:f].to_i)

    @photos = []
    Photo.all.each do |photo|
        fm = photo.familyMatch(@f)
        if photo.familyMatch(@f) == 1
            @photos << photo
        end
    end
    puts 1
  end

  def persona
    if params[:p]
      @p = Person.find(params[:p].to_i)
      @photos = @p.photos.sort_by(&:date)
      @f = @p.childrenof
    else
      @p = nil
      @photos = Photo.all.sort_by(&:date)
    end
  end

  def cumples
    puts 1
  end
end
