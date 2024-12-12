class Car < ApplicationRecord
  belongs_to :brand

  scope :with_priority_for_user, ->(user) {
    preferred_brands_sql = user.preferred_brands.select(:id).to_sql

    select(
      "cars.*",
      Arel.sql(
        "CASE
          WHEN brands.id IN (#{preferred_brands_sql})
            AND cars.price BETWEEN #{user.preferred_price_range.first} AND #{user.preferred_price_range.last}
          THEN 0
          WHEN brands.id IN (#{preferred_brands_sql})
          THEN 1
          ELSE 2
        END AS priority"
      )
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
