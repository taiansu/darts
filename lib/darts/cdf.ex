defmodule Darts.CDF do
  defstruct pool: [], opts: [rate_key: :rate, percision: 4]

  @moduledoc """
  CDF (Cumulative Distribution Function)
  """

  alias Decimal, as: D

  @doc """
  Generate the CDF from a keyword list or a list of map.
  __Time complexity: O(1)__

  If the pool is a list of map, it will try to fetch the rate of item with `:rate` key. You can change it by specifing the `:rate_key` in the option while initializing.

  Options:

      * percision: __default: 4__
      * default: __default: nil__
      * rate_key: __default: :rate__

  ## Example: build from a list of map
      iex> cdf = Darts.CDF.new([%{id: 1, rate: "0.4"}, %{id: 2, rate: "0.3"}, %{id: 3, rate: "0.1"}])
      %Darts.CDF{
        opts: [rate_key: :rate, percision: 4],
        pool: [%{id: 1, rate: "0.4"}, %{id: 2, rate: "0.3"}, %{id: 3, rate: "0.1"}]
      }

  ## Example: build from a keyword list
      iex> cdf = Darts.CDF.new([{1, "0.2"}, {2, "0.3"}, {3, "0.1"}, {4, "0.4"}])
      %Darts.CDF{
        opts: [rate_key: :rate, percision: 4],
        pool: [{1, "0.2"}, {2, "0.3"}, {3, "0.1"}, {4, "0.4"}]
      }

  """
  def new(pool, opts \\ []) do
    %__MODULE__{
      pool: pool,
      opts: Keyword.merge([rate_key: :rate, percision: 4], opts)
    }
  end

  @doc """
  Draw a item from the cdf pool.
  __Time complexity: O(n)__

  #Example
      iex> pool = [%{id: 1, rate: "0.4"}, %{id: 2, rate: "0.3"}, %{id: 3, rate: "0.1"}]
      iex> cdf = Darts.CDF.new(pool)
      iex> result = Darts.CDF.draw(cdf)
      iex> result in [nil | pool]
      true
  """
  def draw(%__MODULE__{pool: pool, opts: opts}) do
    multiplier = 10 |> :math.pow(opts[:percision]) |> trunc

    # TODO: select seeding algorithm
    random_number = :rand.uniform(multiplier)

    result =
      Enum.reduce_while(pool, {:next, 0}, fn i, {:next, accu} ->
        accu = i |> fetch_rate(opts[:rate_key]) |> D.mult(multiplier) |> D.add(accu)
        check(D.lt?(random_number, accu), i, accu)
      end)

    case result do
      {:ok, item} -> item
      _ -> opts[:default]
    end
  end

  defp check(true, item, _accu), do: {:halt, {:ok, item}}
  defp check(false, _item, accu), do: {:cont, {:next, accu}}

  @doc """
  Get the total rate of the data pool.
  Time complexity: O(n)

  ## Example:
      iex> cdf = Darts.CDF.new([{1, "0.2"}, {2, "0.3"}, {3, "0.1"}])
      iex> Darts.CDF.total_rate(cdf)
      #Decimal<0.6>
  """
  def total_rate(%__MODULE__{pool: pool, opts: opts}) do
    Enum.reduce(pool, 0, fn item, accu ->
      item
      |> fetch_rate(opts[:rate_key])
      |> (&add(&1, accu)).()
    end)
  end

  @doc """
  Check if the total rate of the pool equals to 1.
  __Time complexity: O(n)__

  ## Example
      iex> cdf = Darts.CDF.new([{1, "0.2"}, {2, "0.3"}, {3, "0.1"}])
      iex> Darts.CDF.complete?(cdf)
      false
  """
  def complete?(list), do: total_rate(list) |> D.equal?(0)

  defp add(input, d) when is_float(input), do: input |> D.from_float() |> D.add(d)
  defp add(input, d), do: input |> D.new() |> D.add(d)

  defp fetch_rate(item, rate_key) when is_map(item), do: item[rate_key]
  defp fetch_rate({_key, rate}, _), do: rate
end
