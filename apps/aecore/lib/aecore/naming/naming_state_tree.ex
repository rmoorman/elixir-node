defmodule Aecore.Naming.NamingStateTree do
  @moduledoc """
  Top level naming state tree.
  """
  alias Aecore.Naming.NameClaim
  alias Aecore.Naming.NameCommitment
  alias Aeutil.PatriciaMerkleTree
  alias Aeutil.Serialization
  alias MerklePatriciaTree.Trie

  @type namings_state() :: Trie.t()
  @type hash :: binary()

  @spec init_empty() :: namings_state()
  def init_empty do
    PatriciaMerkleTree.new(:naming)
  end

  @spec put(namings_state(), binary(), NameClaim.t() | NameCommitment.t()) :: namings_state()
  def put(tree, key, value) do
    serialized = Serialization.rlp_encode(value)
    PatriciaMerkleTree.enter(tree, key, serialized)
  end

  @spec get(namings_state(), binary()) :: NameClaim.t() | NameCommitment.t() | :none
  def get(tree, key) do
    case PatriciaMerkleTree.lookup(tree, key) do
      {:ok, value} ->
        {:ok, naming} = Serialization.rlp_decode_anything(value)
        naming

      _ ->
        :none
    end
  end

  @spec delete(namings_state(), binary()) :: namings_state()
  def delete(tree, key) do
    PatriciaMerkleTree.delete(tree, key)
  end

  @spec root_hash(namings_state()) :: hash()
  def root_hash(tree) do
    PatriciaMerkleTree.root_hash(tree)
  end

  @spec apply_block_height_on_state!(Chainstate.t(), integer()) :: Chainstate.t()
  def apply_block_height_on_state!(%{naming: naming_state} = chainstate, block_height) do
    updated_naming_state =
      naming_state
      |> Enum.filter(fn {_hash, name_state} -> name_state.expires > block_height end)
      |> Enum.into(%{})

    %{chainstate | naming: updated_naming_state}
  end
end
