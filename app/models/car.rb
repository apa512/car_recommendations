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
    return all if recommended_cars.blank?

    rank_scores = recommended_cars.each_with_object({}) { |car, hash| hash[car['car_id']] = car['rank_score'] }
    
    select(
      "cars.*",
      Arel.sql(
        "CASE 
          #{rank_scores.map { |id, score| "WHEN cars.id = #{id} THEN #{score}" }.join(' ')}
          ELSE NULL 
        END AS rank_score"
      )
    )
  }
end
