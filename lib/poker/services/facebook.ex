defmodule PokerEx.Services.Facebook do
  @app_id System.get_env("FB_TEST_APP_ID")
  @app_secret System.get_env("FB_TEST_APP_SEC")
  @endpoint "https://graph.facebook.com/"
  @api_vsn "v2.9/"
  
  @type response :: %HTTPotion.Response{}
  
  @spec notify_user(%{user_id: String.t, template: String.t, return_url: String.t}) :: response
  def notify_user(%{user_id: id, template: template, return_url: url}) do
    template = template |> URI.encode()
    HTTPotion.post("#{@endpoint}#{@api_vsn}/#{id}/notifications?access_token=#{@app_id}|#{@app_secret}&template=#{template}&href=#{url}",
    [body: "", headers: ["Content-Type": "application/json"]])
  end
end