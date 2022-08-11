defmodule Rokka.SourceImages do
  @moduledoc """
  APIs dealing with multiple Rokka source images.
  """

  alias Rokka.SourceImage
  alias Tesla.Multipart
  require Logger

  def all_source_images_stream() do
    client = Rokka.client()

    Stream.resource(
      fn ->
        "#{source_images_base_url()}?limit=1000"
      end,
      &process_source_image_stream_items(client, &1),
      fn _acc -> nil end
    )
  end

  def create(client, file_name, file_contents) do
    mp =
      Multipart.new()
      |> Multipart.add_file_content(file_contents, file_name)

    {:ok, response} = Tesla.post(client, source_images_base_url(), mp)

    {:ok, image_response} = get_image_from_json_response(response.body)

    SourceImage.json_response_to_source_image(image_response)
  end

  def delete(client, hash) do
    {:ok, response} =
      Tesla.delete(
        client,
        "#{source_images_base_url()}/#{hash}"
      )

    if response.status < 200 or response.status >= 500 do
      raise "Received unexpected non-ok response from Rokka: #{inspect(response)}"
    else
      Logger.warn("Source image #{hash} deleted from Rokka.")
      :ok
    end
  end

  @doc """
  Get source image from Rokka, if exists.

  Returns nil otherwise.
  """
  def get_by_binary_hash(client, binary_hash) do
    {:ok, response} = Tesla.get(client, "#{source_images_base_url()}?binaryHash=#{binary_hash}")

    cond do
      response.status == 200 && Map.get(response.body, "total") == 1 ->
        src_img = Enum.at(Map.get(response.body, "items"), 0)

        SourceImage.json_response_to_source_image(src_img)

      response.status == 404 ->
        nil
    end
  end

  def get_by_path(client, next_path) do
    {:ok, %Tesla.Env{body: body, status: 200}} = Tesla.get(client, next_path)

    total = Map.get(body, "total", "unknown")
    next_path = get_in(body, ["links", "next", "href"])
    Logger.info("Rokka result received. Total: #{total}, next path: #{next_path}")
    {:ok, {body["items"], next_path}}
  end

  def update_user_metadata_field(client, hash, fieldname, value) do
    {:ok, response} =
      Tesla.put(
        client,
        "#{source_images_base_url()}/#{hash}/meta/user/#{fieldname}",
        value
      )

    if response.status < 200 or response.status >= 400 do
      raise "Received unexpected non-ok response from Rokka: #{inspect(response)}"
    else
      :ok
    end
  end

  def source_images_base_url() do
    organization =
      Application.get_env(:marsvin, Rokka, [])
      |> Keyword.get(:organization)

    "/sourceimages/#{organization}"
  end

  defp get_image_from_json_response(resp) do
    # Rokka is a little inconsistent with the way it responds to image creation
    # so handle the different known variants here.
    cond do
      Map.has_key?(resp, "hash") -> {:ok, resp}
      resp["total"] != 1 -> {:err, :unexpected_result_count, resp["total"]}
      Map.has_key?(resp, "items") -> {:ok, Enum.at(resp["items"], 0)}
      Map.has_key?(resp, "sourceimages") -> {:ok, Enum.at(resp["sourceimages"], 0)}
    end
  end

  defp process_source_image_stream_items(client, next_path)
       when is_binary(next_path) and byte_size(next_path) > 0 do
    {:ok, {items, next_path}} = get_by_path(client, next_path)

    {items, next_path}
  end

  defp process_source_image_stream_items(_client, _path), do: {:halt, nil}
end
