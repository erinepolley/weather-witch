defmodule Weatherwitch do
  require Logger
  alias AppKey

  def loop() do
    receive do
      {sender_pid, location} ->
        send(sender_pid, {:ok, temperature_of(location)})

      _ ->
        IO.puts("don't know how to process this message")
    end

    loop()
  end

  def temps_for_cities(city_list) do
    city_list
    |> Enum.each(fn city ->
      pid = spawn(Weatherwitch, :loop, [])
      send(pid, {self(), city})
    end)
  end

  @spec temperature_of(binary) :: binary()
  def temperature_of(location) do
    result = url_for(location) |> HTTPoison.get() |> parse_response

    case result do
      {:ok, cel_temp, fah_temp} ->
        "#{location}: #{fah_temp}°F (#{cel_temp}°C)"

      error ->
        IO.inspect(error, label: "what is the error?")
        "#{location} not found"
    end
  end

  defp url_for(location) do
    key = AppKey.key()
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{key}"
  end

  @spec parse_response(tuple()) :: {:ok, integer(), integer()} | :error
  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> JSON.decode!()
    |> get_temp_from_body()
    |> compute_temps()
  end

  defp parse_response(error) do
    Logger.error("OpenWeather GET error: #{inspect(error)}")
    :error
  end

  @spec get_temp_from_body(map()) :: number()
  defp get_temp_from_body(json) do
    json["main"]["temp"]
  end

  @spec compute_temps(number()) :: tuple() | :error
  defp compute_temps(temp) do
    try do
      cel_temp = (temp - 273.15) |> Float.round(1)
      fah_temp = (cel_temp * 9 / 5 + 32) |> Float.round(1)
      {:ok, cel_temp, fah_temp}
    rescue
      error ->
        Logger.error("Temperature calculation error: #{inspect(error)}")
        :error
    end
  end
end
