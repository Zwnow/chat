defmodule Chat.Token do
  use Joken.Config

  def env_signer, do: Joken.Signer.create("HS256", System.fetch_env!("JWT_SECRET"))

  def verify_token(token) do
    case Chat.Token.verify_and_validate(token, env_signer()) do
      {:ok, claims} -> {:ok, claims}
      {:error, _reason} -> {:error, :invalid_token}
    end
  end
end
