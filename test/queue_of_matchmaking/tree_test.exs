defmodule QueueOfMatchmaking.TreeTest do
  use ExUnit.Case, async: true
  alias QueueOfMatchmaking.Tree

  defp build_tree(items) do
    Enum.reduce(items, Tree.empty(), fn {k, v}, acc ->
      Tree.insert(k, v, acc)
    end)
  end

  test "empty/0, insert/3, and lookup/2 work" do
    tree = Tree.empty()
    assert Tree.lookup(10, tree) == :none

    tree = Tree.insert(10, "a", tree)
    assert Tree.lookup(10, tree) == {:value, "a"}

    tree = Tree.insert(20, "b", tree)
    assert Tree.lookup(10, tree) == {:value, "a"}
    assert Tree.lookup(20, tree) == {:value, "b"}
  end

  test "delete/2 removes a key" do
    tree = build_tree([{10, "a"}, {20, "b"}])
    assert Tree.lookup(10, tree) == {:value, "a"}

    tree = Tree.delete(10, tree)
    assert Tree.lookup(10, tree) == :none
    assert Tree.lookup(20, tree) == {:value, "b"}
  end

  describe "next/2" do
    # Tree for testing: 10 -> "a", 20 -> "b", 30 -> "c"
    setup do
      tree = build_tree([{10, "a"}, {20, "b"}, {30, "c"}])
      %{tree: tree}
    end

    test "finds the next item when key exists", %{tree: tree} do
      # Key 10 exists, next is 20
      assert Tree.next(10, tree) == {20, "b"}
    end

    test "finds the next item when key does not exist", %{tree: tree} do
      # Key 15 does not exist, next is 20
      assert Tree.next(15, tree) == {20, "b"}
    end

    test "returns :none when it's the last item", %{tree: tree} do
      # Key 30 exists, no next
      assert Tree.next(30, tree) == :none
    end

    test "returns :none when key is greater than all items", %{tree: tree} do
      assert Tree.next(40, tree) == :none
    end

    test "finds first item when key is less than all items", %{tree: tree} do
      assert Tree.next(5, tree) == {10, "a"}
    end
  end

  describe "prev/2" do
    # Tree for testing: 10 -> "a", 20 -> "b", 30 -> "c"
    setup do
      tree = build_tree([{10, "a"}, {20, "b"}, {30, "c"}])
      %{tree: tree}
    end

    test "finds the previous item when key exists", %{tree: tree} do
      # Key 20 exists, prev is 10
      assert Tree.prev(20, tree) == {10, "a"}
    end

    test "finds the previous item when key does not exist", %{tree: tree} do
      # Key 25 does not exist, prev is 20
      assert Tree.prev(25, tree) == {20, "b"}
    end

    test "returns :none when it's the first item", %{tree: tree} do
      # Key 10 exists, no prev
      assert Tree.prev(10, tree) == :none
    end

    test "returns :none when key is less than all items", %{tree: tree} do
      assert Tree.prev(5, tree) == :none
    end

    test "finds last item when key is greater than all items", %{tree: tree} do
      assert Tree.prev(40, tree) == {30, "c"}
    end
  end
end
