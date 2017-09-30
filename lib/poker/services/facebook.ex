defmodule PokerEx.Services.Facebook do
  @app_id System.get_env("FACEBOOK_APP_ID")
  @app_secret System.get_env("FACEBOOK_APP_SECRET")
  @endpoint "https://graph.facebook.com/"
  @api_vsn "v2.9/"

  @type response :: %HTTPotion.Response{}

  @spec notify_user(%{user_id: String.t, template: String.t, return_url: String.t}) :: response
  def notify_user(%{user_id: id, template: template, return_url: url}, app_id \\ @app_id, app_secret \\ @app_secret) do
    case {app_id, app_secret} do
      {nil, nil} -> fb_credentials_exception()
      {nil, _} -> fb_credentials_exception()
      {_, nil} -> fb_credentials_exception()
      _ ->
        template = template |> URI.encode()
        HTTPotion.post("#{@endpoint}#{@api_vsn}/#{id}/notifications?access_token=#{app_id}|#{app_secret}&template=#{template}&href=#{url}",
        [body: "", headers: ["Content-Type": "application/json"]])
    end
  end

  defp fb_credentials_exception do
    raise "app_id and app_secret are required to use the Facebook notification service"
  end
end
