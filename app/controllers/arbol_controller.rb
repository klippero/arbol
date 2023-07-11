class ArbolController < ApplicationController
  def familia
    @f = Family.find(params[:id].to_i)
  end
end
