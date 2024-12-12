require "test_helper"

class RecommendationsServiceTest < ActiveSupport::TestCase
  def setup
    DatabaseCleaner.clean
    Rails.application.load_seed

    @user = User.first
    @rank_scores = JSON.parse(
      File.read(Rails.root.join("test/fixtures/recommended_cars.json"))
    )
  end

  def rank_scores
  end

  test "returns the best match first" do
    result = RecommendationsService.call(@user, { page: 1, per_page: 25, rank_scores: @rank_scores })

    expected_result = {
      id: 179,
      brand: {
        id: 39,
        name: "Volkswagen"
      },
      model: "Derby",
      price: 37230,
      rank_score: 0.945,
      label: "perfect_match"
    }
    
    assert_equal expected_result, result.first
  end

  test "filters by brand name" do
    result = RecommendationsService.call(@user, { page: 1, per_page: 25, query: "oyot" })
    
    assert_not_empty result
    assert result.all? { |c| c[:brand][:name].include?("Toyota") }
  end

  test "respects pagination" do
    first_page = RecommendationsService.call(@user, { page: 1, per_page: 2 })
    assert_equal 2, first_page.length

    second_page = RecommendationsService.call(@user, { page: 2, per_page: 2 })
    assert_equal 2, second_page.length

    assert_not_equal first_page.first[:id], second_page.first[:id]
  end

  test "works when the recommandation service is down" do
    result = RecommendationsService.call(@user, { page: 1, per_page: 25, rank_scores: [] })
    assert_not_empty result
    assert_equal "perfect_match", result.first[:label]
  end

  test "filters by price range" do
    result = RecommendationsService.call(@user, { 
      page: 1, 
      per_page: 25, 
      price_min: 35000,
      price_max: 40000 
    })

    assert_not_empty result
    assert result.all? { |c| c[:price] >= 35000 && c[:price] <= 40000 }
  end
end 
