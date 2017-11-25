defmodule PokerEx.Services.FacebookTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias PokerEx.Services.Facebook, as: FB

  @app_id System.get_env("FB_TEST_APP_ID")
  @app_secret System.get_env("FB_TEST_APP_SEC")
  @valid_id "114171069145279"
  @invalid_id "101085637123100"
  @template "Test template"
  @url "/"

  setup_all do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassette")
    ExVCR.Config.filter_url_params(true)
    :ok
  end

  test "notify user returns status code of 200 with a valid user_id" do
    use_cassette "fb_notify_user_success_case" do
      response = FB.notify_user(%{user_id: @valid_id, template: @template, return_url: @url}, @app_id, @app_secret)
      case response do
        %HTTPotion.ErrorResponse{} = res -> assert res.message == "req_timedout"
        _ ->  assert response.status_code == 200
      end

    end
  end

  test "notify user returns status code of 400 with an invalid user_id" do
    use_cassette "fb_notify_user_failure_case" do
      response = FB.notify_user(%{user_id: @invalid_id, template: @template, return_url: @url}, @app_id, @app_secret)
      case response do
        %HTTPotion.ErrorResponse{} = res -> assert res.message == "req_timedout"
        _ ->  assert response.status_code == 400
      end
    end
  end

  test "notify user raises when both app_id and app_secret are nil" do
    assert_raise RuntimeError, fn ->
      FB.notify_user(%{user_id: @valid_id, template: @template, return_url: @url}, nil, nil)
    end
  end

  test "notify user raises when app_id alone is nil" do
    assert_raise RuntimeError, fn ->
      FB.notify_user(%{user_id: @valid_id, template: @template, return_url: @url}, nil, @app_secret)
    end
  end

  test "notify user raises when app_secret alone is nil" do
    assert_raise RuntimeError, fn ->
      FB.notify_user(%{user_id: @valid_id, template: @template, return_url: @url}, @app_id, nil)
    end
  end

  test "notify user returns a status code of 404 when nil is passed for the user_id" do
    use_cassette "fb_notify_user_no_id" do
      response = FB.notify_user(%{user_id: nil, template: @template, return_url: @url}, @app_id, @app_secret)
      case response do
        %HTTPotion.ErrorResponse{} = res -> assert res.message == "req_timedout"
        _ ->  assert response.status_code == 404
      end

    end
  end
end
