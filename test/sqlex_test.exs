defmodule SqlexTest do
  use ExUnit.Case
  doctest Sqlex

  test "greets the world" do
    assert Sqlex.hello() == :world
  end
end
