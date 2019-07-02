defmodule Darts.CDFTest do
  use ExUnit.Case
  alias Darts.CDF
  doctest Darts.CDF

  test "greets the world" do
    assert CDF.new([]) == %CDF{}
  end
end
