defmodule PokerEx.Services.FacebookTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock
  alias PokerEx.Services.Facebook, as: FB
  
  @valid_id "101994257035674"
  @template "Test template"
  @url "/"
  
  setup_all do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassette")
    ExVCR.Config.filter_url_params(true)
    :ok
  end
  
  test "notify user returns status code of 200 when facebook_id exists" do
    use_cassette "fb_notify_user_success_case" do
      response = FB.notify_user(%{user_id: @valid_id, template: @template, return_url: @url})
      assert response.status_code == 200
    end
  end
end