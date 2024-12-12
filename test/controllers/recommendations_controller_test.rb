require "test_helper"

class RecommendationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    DatabaseCleaner.clean
    Rails.application.load_seed

    @user = User.first
    @rank_scores = JSON.parse(
      File.read(Rails.root.join("test/fixtures/recommended_cars.json"))
    )
  end

  test "returns 404 when user not found" do
    get user_recommendations_path(user_id: 999)
    assert_response :not_found
    assert_equal({ "error" => "User not found" }, JSON.parse(response.body))
  end

  test "returns recommendations for valid user" do
    stub_s3_request

    get user_recommendations_path(user_id: @user.id)
    assert_response :success

    result = JSON.parse(response.body)
    assert_not_empty result

    first_car = result.first
    assert_equal 179, first_car["id"]
    assert_equal "Volkswagen", first_car["brand"]["name"]
    assert_equal "Derby", first_car["model"]
    assert_equal 37230, first_car["price"]
    assert_equal 0.945, first_car["rank_score"]
    assert_equal "perfect_match", first_car["label"]
  end

  test "filters results by query parameter" do
    stub_s3_request

    get user_recommendations_path(user_id: @user.id, query: "Volks")
    assert_response :success

    result = JSON.parse(response.body)
    assert_not_empty result
    assert result.all? { |car| car["brand"]["name"].include?("Volkswagen") }
  end

  test "respects pagination parameters" do
    stub_s3_request

    get user_recommendations_path(user_id: @user.id, page: 1, per_page: 5)
    assert_response :success

    result = JSON.parse(response.body)
    assert_equal 5, result.length
  end

  private

  def stub_s3_request
    stub_request(:get, /.*s3\.amazonaws\.com.*/)
      .to_return(
        status: 200,
        body: @rank_scores.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end 
