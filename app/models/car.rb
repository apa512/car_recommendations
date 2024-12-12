class Car < ApplicationRecord
  belongs_to :brand

  scope :with_priority_for_user, ->(user) {
    joins("LEFT JOIN user_preferred_brands upb ON upb.brand_id = cars.brand_id AND upb.user_id = #{user.id}")
      .select(
        "cars.*",
        "CASE
          WHEN upb.id IS NOT NULL AND cars.price BETWEEN #{user.preferred_price_range.first} AND #{user.preferred_price_range.last}
            THEN 0
          WHEN upb.id IS NOT NULL
            THEN 1
          ELSE 2
        END AS priority"
      )
  }

  scope :with_rank_scores, ->(recommended_cars) {
    select(
      "cars.*",
      Arel.sql(
        if recommended_cars.blank?
          "NULL::float AS rank_score"
        else
          "CASE 
            #{recommended_cars.map { |car| "WHEN cars.id = #{car['car_id']} THEN #{car['rank_score']}::float" }.join(' ')}
            ELSE NULL::float 
          END AS rank_score"
        end
      )
    )
  }
end
