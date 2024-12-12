class RecommendationsController < ActionController::API
  DEFAULT_PER_PAGE = 20

  def index
    user = User.find_by(id: params[:user_id])

    if (!user.present?)
      return render json: { error: "User not found" }, status: :not_found
    end

    rank_scores = Rails.cache.fetch("s3_recommended_cars_#{user.id}", expires_in: 6.hours) do
      begin
        response = HTTP.get("https://bravado-images-production.s3.amazonaws.com/recomended_cars.json?user_id=#{user.id}")
        JSON.parse(response.body)
      rescue
        []
      end
    end

    cars = RecommendationsService.call(user, {
      page: params.fetch(:page, 1).to_i,
      per_page: params.fetch(:per_page, DEFAULT_PER_PAGE).to_i,
      query: params[:query],
      price_min: params[:price_min],
      price_max: params[:price_max],
      rank_scores: rank_scores
    })

    render json: cars
  end
end
