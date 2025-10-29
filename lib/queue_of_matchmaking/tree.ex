defmodule QueueOfMatchmaking.Tree do
  @moduledoc """
  A wrapper around Erlang's `:gb_trees` to provide a consistent API
  Older stdlib versions lack of functions like
  `prev/2`, `next/2`

  https://www.erldocs.com/18.0/stdlib/gb_trees.html?i=358
  """

  # ------------------------------------------------------------------
  # Pass-through functions (API is the same)
  # ------------------------------------------------------------------

  @doc "Pass-through to :gb_trees.empty/0"
  def empty, do: :gb_trees.empty()

  @doc "Pass-through to :gb_trees.get/2"
  def lookup(key, tree), do: :gb_trees.lookup(key, tree)

  @doc "Pass-through to :gb_trees.put/3"
  def insert(key, value, tree), do: :gb_trees.enter(key, value, tree)

  @doc "Pass-through to :gb_trees.del/2"
  def delete(key, tree), do: :gb_trees.delete_any(key, tree)

  # ------------------------------------------------------------------
  # Custom-implemented functions for older stdlib
  # ------------------------------------------------------------------

  @doc """
  Finds the largest key-value pair where the key is less than `key`.

  WARNING: This is an O(N), as there is no
  efficient way to find the previous item. It must convert the
  entire tree to a list.
  """
  def prev(key, tree) do
    # This is O(N)
    all_pairs = :gb_trees.to_list(tree)
    # This is also O(N)
    pairs_before = Enum.filter(all_pairs, fn {k, _v} -> k < key end)

    case pairs_before do
      [] ->
        # No items found with a key less than `key`
        :none

      _ ->
        # Returns the last {k,v} tuple in the filtered list
        List.last(pairs_before)
    end
  end

  @doc """
  Finds the smallest key-value pair where the key is greater than `key`.
  This remains O(log N) as it can use the iterator.
  """
  def next(key, tree) do
    # iterator_from/2 points to the smallest key >= `key`.
    iter = :gb_trees.iterator_from(key, tree)

    case :gb_trees.lookup(key, tree) do
      {:value, _} ->
        # Key *exists* in the tree. The iterator is pointing right at it.
        # We must advance the iterator *past* it to find the next one.
        # Discard the item at `key`
        {_, _, iter} = :gb_trees.next(iter)

        case :gb_trees.next(iter) do
          :none -> :none
          {key, value, _} -> {key, value}
        end

      :none ->
        # Key does *not* exist. The iterator is *already* pointing at
        # the first item *greater* than `key`. We just return it.
        case :gb_trees.next(iter) do
          :none -> :none
          {key, value, _} -> {key, value}
        end
    end
  end
end
