defmodule Rokka.SourceImage do
  @moduledoc """
  Define source image struct.
  """

  @enforce_keys [:hash]
  defstruct [
    :hash,
    :short_hash,
    :binary_hash,
    :created,
    :name,
    :mimetype,
    :format,
    :size,
    :width,
    :height,
    :organization,
    :link
  ]

  def json_response_to_source_image(resp) do
    %__MODULE__{
      hash: resp["hash"],
      short_hash: resp["short_hash"],
      binary_hash: resp["binary_hash"],
      created: resp["created"],
      name: resp["name"],
      mimetype: resp["mimetype"],
      format: resp["format"],
      size: resp["size"],
      width: resp["width"],
      height: resp["height"],
      organization: resp["organization"],
      link: resp["link"]
    }
  end
end
