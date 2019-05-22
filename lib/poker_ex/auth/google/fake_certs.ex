defmodule PokerEx.Auth.Google.FakeCerts do

  @spec get :: HTTPotion.Response.t()

  def get do
    %HTTPotion.Response{
      body: "{\n  \"keys\": [\n    {\n      \"kid\": \"2c3fac16b73fc848d426d5a225ac82bc1c02aefd\",\n      \"e\": \"AQAB\",\n      \"kty\": \"RSA\",\n      \"alg\": \"RS256\",\n      \"n\": \"timkjBhJ0F7fgr5-ySitSoSNmUqYcVKgWaUd52HUYPowNwdw1vOWYHuSVol47ssOOaF7dRjgoVHyo_qNgy7rdlU0pUidiYTB6lwSAQYyvk6WAipkpzWH8cr875BMUREyN5aEy-iKsYTB3HeT-gEnLI697eETZtSB8rwlDvyRy7l0wD1GVj4SKTd4P2a2qNCgCfkZzzKqPgmIrPtwkEZb43Cz-A7AfwyXxrMljTkghKkp4zkFRtXplIGjC5LcPZRLSseTYwHP2pV4AtE5KzYxDmtDmY6RyZaMZc_WXNvKBFcO3Rypo4F63lE2x5f7EIbpATWydXq3CMLitLsPor22ow\",\n      \"use\": \"sig\"\n    },\n    {\n      \"kid\": \"07a082839f2e71a9bf6c596996b94739785afdc3\",\n      \"e\": \"AQAB\",\n      \"kty\": \"RSA\",\n      \"alg\": \"RS256\",\n      \"n\": \"9Y5kfSJyw-GyM4lSXNCVaMKmDdOkYdu5ZhQ7E-8nfae-CPPsx3IZjdUrrv_AoKhM3vsZW_Z3Vucou53YZQuHFpnAa6YxiG9ntpScviU1dhMd4YyUtNYWVBxgNemT9dhhj2i32ez0tOj7o0tGh2Yoo2LiSXRDT-m2zwBImYkBksws4qq_X3jZhlfYkznrCJGjVhKEHzlQy5BBqtQtN5dXFVi-zRZ0-m7oiNW_2wivjw_99li087PNFSeyHpgxjbg30K2qnm1T8gVhnzqf8xnPW9vZFyc_8-3qmbQeDedB8YWyzojM3hDLsHqypP84MSOmejmi0c2b836oc-pI8seXwQ\",\n      \"use\": \"sig\"\n    }\n  ]\n}\n",
      headers: %HTTPotion.Headers{
        hdrs: %{
          "accept-ranges" => "none",
          "alt-svc" => "quic=\":443\"; ma=2592000; v=\"46,44,43,39\"",
          "cache-control" => "public, max-age=18033, must-revalidate, no-transform",
          "content-type" => "application/json; charset=UTF-8",
          "date" => "Tue, 21 May 2019 19:32:30 GMT",
          "expires" => "Wed, 22 May 2019 00:33:03 GMT",
          "server" => "ESF",
          "transfer-encoding" => "chunked",
          "vary" => ["Origin,Accept-Encoding", "Referer", "X-Origin"],
          "x-content-type-options" => "nosniff",
          "x-frame-options" => "SAMEORIGIN",
          "x-xss-protection" => "0"
        }
      },
      status_code: 200
    }
  end
end
