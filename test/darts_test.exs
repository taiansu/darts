defmodule DartsTest do
  use ExUnit.Case
  doctest Darts

  test "greets the world" do
    assert Darts.hello() == :world
  end
end
