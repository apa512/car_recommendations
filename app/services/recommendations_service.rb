class RecommendationsService
  def self.call(user, params)
    page = params.fetch(:page)
    per_page = params.fetch(:per_page)
    query = params[:query]
    price_min = params[:price_min]
    price_max = params[:price_max]
    rank_scores = params[:rank_scores] || []

    cars = Car.joins(:brand)
      .with_priority_for_user(user)
      .with_rank_scores(rank_scores)

    cars = cars.where("cars.price >= ?", price_min) if price_min.present?
    cars = cars.where("cars.price <= ?", price_max) if price_max.present?
    cars = cars.where("brands.name ILIKE :query", query: "%#{query}%") if query.present?

    cars = cars.select("brands.name AS brand_name")
      .order(priority: :asc)
      .order("rank_score DESC NULLS LAST")
      .order(price: :asc)
      .offset((page - 1) * per_page)
      .limit(per_page)

    cars.map do |car|
      {
        id: car.id,
        model: car.model,
        price: car.price,
        rank_score: car.rank_score,
        label: case car.priority
               when 0 then "perfect_match"
               when 1 then "good_match"
               else nil
               end,
        brand: { id: car.brand_id, name: car.brand_name }
      }
    end
  end
end

