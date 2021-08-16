defmodule PingPong do
  @moduledoc """
  These functions can be spawned as processes
  and talk to each other (or any other process for that matter).
  """
  def ping do
    receive do
      "ping" -> IO.puts("pong")
      _ -> IO.puts("no pong for you")
    end

    ping()
  end

  def pong do
    receive do
      "pong" -> IO.puts("ping")
      _ -> IO.puts("no ping for you")
    end

    pong()
  end

  def process_me_bro() do
    receive do
      {pid, "hi"} ->
        Logger.info("received message 'hi'")
        send(pid, "hello")

      {pid, "no"} ->
        Logger.info("received message 'no'")
        send(pid, "I received your message, but I don't know what to say")

      {pid, other} ->
        Logger.error("This process received a message of #{inspect(other)}")
        send(pid, "#{inspect(other)} was not a valid message.")
    end

    # keeps the process alive after it receives a message
    process_me_bro()
  end
end
