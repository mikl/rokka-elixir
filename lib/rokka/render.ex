defmodule Rokka.Render do
  def stack_url(stack, hash, options \\ []) do
    ([
       # TODO: make this configurable.
       "https://myorg.rokka.io",
       stack
     ] ++ options ++ [hash <> ".jpg"])
    |> Enum.join("/")
  end
end
