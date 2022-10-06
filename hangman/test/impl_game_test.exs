defmodule HangmanImplGameTest do
  use ExUnit.Case
  alias Hangman.Impl.Game

  test "new game returns structure" do
    game = Game.new_game()
    assert game.turns_left == 7
    assert game.game_state == :initializing
    assert length(game.letters) > 0
  end

  test "new game returns correct word" do
    game = Game.new_game("wombat")
    assert game.turns_left == 7
    assert game.game_state == :initializing
    assert game.letters == ["w", "o", "m", "b", "a", "t"]
  end

  test "state doesn't change if a game is won or lost" do
    for state <- [:won, :lost] do
      game = Game.new_game("wombat")
      game = Map.put(game, :game_state, state)
      {new_game, _tally} = Game.make_move(game, "x")
      assert new_game == game
    end
  end

  test "a duplicate letter is reported" do
    game = Game.new_game()
    {game, _tally} = Game.make_move(game, "x")
    assert game.game_state != :already_used
    {game, _tally} = Game.make_move(game, "y")
    assert game.game_state != :already_used
    {game, _tally} = Game.make_move(game, "x")
    assert game.game_state == :already_used
  end

  test "we record letters used" do
    game = Game.new_game()
    {game, _tally} = Game.make_move(game, "x")
    {game, _tally} = Game.make_move(game, "y")
    {game, _tally} = Game.make_move(game, "x")
    assert MapSet.equal?(game.used, MapSet.new(["x", "y"]))
  end

  test "we recognize a letter in the word" do
    game = Game.new_game("wombat")
    {_game, tally} = Game.make_move(game, "m")
    assert tally.game_state == :good_guess
    {_game, tally} = Game.make_move(game, "t")
    assert tally.game_state == :good_guess
  end

  test "we recognize a letter not in the word" do
    game = Game.new_game("wombat")
    {_game, tally} = Game.make_move(game, "q")
    assert tally.game_state == :bad_guess
    {_game, tally} = Game.make_move(game, "m")
    assert tally.game_state == :good_guess
    {_game, tally} = Game.make_move(game, "z")
    assert tally.game_state == :bad_guess
  end

  test "can handle a sequence of move" do
    # hello
    [
      # guess | state   |turns letters                used
      ["a", :bad_guess, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["a", :already_used, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["e", :good_guess, 6, ["_", "e", "_", "_", "_"], ["a", "e"]],
      ["x", :bad_guess, 5, ["_", "e", "_", "_", "_"], ["a", "e", "x"]]
    ]
    |> test_sequence_of_moves()
  end

  test "can handle a winning game" do
    # hello
    [
      # guess | state   |turns letters                used
      ["a", :bad_guess, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["a", :already_used, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["e", :good_guess, 6, ["_", "e", "_", "_", "_"], ["a", "e"]],
      ["x", :bad_guess, 5, ["_", "e", "_", "_", "_"], ["a", "e", "x"]],
      ["h", :good_guess, 5, ["h", "e", "_", "_", "_"], ["a", "e", "h", "x"]],
      ["l", :good_guess, 5, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l", "x"]],
      ["p", :bad_guess, 4, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l", "p", "x"]],
      ["o", :won, 4, ["h", "e", "l", "l", "o"], ["a", "e", "h", "l", "o", "p", "x"]]
    ]
    |> test_sequence_of_moves()
  end

  test "can handle a losing game" do
    # hello
    [
      # guess | state   |turns letters                used
      ["a", :bad_guess, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["a", :already_used, 6, ["_", "_", "_", "_", "_"], ["a"]],
      ["e", :good_guess, 6, ["_", "e", "_", "_", "_"], ["a", "e"]],
      ["x", :bad_guess, 5, ["_", "e", "_", "_", "_"], ["a", "e", "x"]],
      ["h", :good_guess, 5, ["h", "e", "_", "_", "_"], ["a", "e", "h", "x"]],
      ["l", :good_guess, 5, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l", "x"]],
      ["p", :bad_guess, 4, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l", "p", "x"]],
      ["w", :bad_guess, 3, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l", "p", "w", "x"]],
      ["y", :bad_guess, 2, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l", "p", "w", "x", "y"]],
      ["z", :bad_guess, 1, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l", "p", "w", "x", "y", "z"]],
      ["u", :lost, 0, ["h", "e", "l", "l", "_"], ["a", "e", "h", "l", "p", "u", "w", "x", "y", "z"]],
    ]
    |> test_sequence_of_moves()
  end

  def test_sequence_of_moves(script) do
    game = Game.new_game("hello")
    Enum.reduce(script, game, &check_one_move/2)
  end

  defp check_one_move([guess, state, turns, letters, used], game) do
    {game, tally} = Game.make_move(game, guess)

    assert tally.game_state == state
    assert tally.turns_left == turns
    assert tally.letters == letters
    assert tally.used == used

    game
  end
end
