%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_caller_address)

const COOPERATE = 0
const DEFECT = 1

const NUM_ROUNDS = 10

struct Move:
    member player1_move : felt
    member player2_move : felt
end

struct Score:
    member player1_score : felt
    member player2_score : felt
end

@contract_interface
namespace IPlayerStrategy:
    func execute_strategy(
        prev_moves_len : felt, 
        prev_moves : Move*, 
        move_num : felt,
        player_num : felt,
    ) -> (strategy : felt):
    end
end

@storage_var
func table(move1 : felt, move2 : felt) -> (score : (felt, felt)):
end

@storage_var
func strategy_contracts(player_id : felt) -> (strategy_address : felt):
end

@storage_var
func player_id_to_address(player_id : felt) -> (player_address : felt):
end

@storage_var
func player_address_to_id(player_address : felt) -> (player_id : felt):
end

@storage_var
func registered_players_len() -> (registered_players_len : felt):
end

@storage_var
func points(player_id : felt) -> (points : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    table.write(COOPERATE, COOPERATE, (2, 2))
    table.write(COOPERATE, DEFECT, (-3, 5))
    table.write(DEFECT, COOPERATE, (5, -3))
    table.write(DEFECT, DEFECT, (-1, -1))

    return ()
end

@view
func get_player_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_address : felt
) -> (player_id : felt):
    return player_address_to_id.read(player_address)
end

@view
func get_player_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_id : felt
) -> (player_address : felt):
    return player_id_to_address.read(player_id)
end

@view
func get_player_points{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_id : felt
) -> (points : felt):
    return points.read(player_id)
end

@external
func register_strategy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(strategy_address : felt):
    let (caller_address) = get_caller_address()

    let (player_id) = player_address_to_id.read(caller_address)
    # if already registered, overwrite strategy
    let (is_registered) = is_not_zero(player_id)
    if is_registered == 1:
        strategy_contracts.write(player_id, strategy_address)
        return ()
    end

    let (curr_id) = registered_players_len.read()
    let player_id = curr_id + 1
    registered_players_len.write(player_id)

    player_id_to_address.write(player_id, caller_address)
    player_address_to_id.write(caller_address, player_id)

    strategy_contracts.write(player_id, strategy_address)
    return ()
end

@view
func play{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    # reset scores?
    
    let (tot_players) = registered_players_len.read()

    _recursive_play(tot_players - 1, tot_players)

    return ()

end

func _recursive_play{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(against : felt, num_players : felt):
    alloc_locals

    if num_players == 1:
        return ()
    end

    if against == 0:
        return _recursive_play(num_players - 2, num_players - 1)
    end

    let player1_id = num_players
    let player2_id = against

    let (strat1) = strategy_contracts.read(player1_id)
    let (strat2) = strategy_contracts.read(player2_id)

    let (old_points1) = points.read(player1_id)
    let (old_points2) = points.read(player2_id)

    let (score) = play_vs(strat1, strat2, NUM_ROUNDS)

    let new_points1 = old_points1 + score.player1_score
    let new_points2 = old_points2 + score.player2_score

    points.write(player1_id, new_points1)
    points.write(player2_id, new_points2)

    return _recursive_play(against - 1, num_players)

end

@view
func play_vs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    strategy1_address : felt, 
    strategy2_address : felt, 
    num_rounds : felt
) -> (result : Score):
    alloc_locals

    let scores = Score(0,0)
    let (moves : Move*) = alloc()
    let (score_final) = _recurse_play_vs(strategy1_address, strategy2_address, num_rounds, 0, moves, 0, scores)
    return (score_final)
end

func _recurse_play_vs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    strategy1_address : felt,
    strategy2_address : felt,
    num_rounds : felt,
    moves_len : felt,
    moves : Move*,
    idx : felt,
    scores : Score
) -> (score_final : Score):
    alloc_locals

    if idx == num_rounds:
        return (scores)
    end

    let (m1) = IPlayerStrategy.execute_strategy(
        contract_address = strategy1_address,
        prev_moves_len = moves_len,
        prev_moves = moves,
        move_num = idx,
        player_num = 1
    )

    let (m2) = IPlayerStrategy.execute_strategy(
        contract_address = strategy2_address,
        prev_moves_len = moves_len,
        prev_moves = moves,
        move_num = idx,
        player_num = 2
    )

    let (scores_round) = table.read(m1, m2)
    let score_nxt_p1 = scores.player1_score + scores_round[0]
    let score_nxt_p2 = scores.player2_score + scores_round[1]

    let score_nxt = Score(score_nxt_p1, score_nxt_p2)

    let round_move = Move(m1, m2)
    assert moves[idx] = round_move

    let (score_final) = _recurse_play_vs(
        strategy1_address,
        strategy2_address,
        num_rounds,
        moves_len + 1,
        moves,
        idx + 1,
        score_nxt
    )

    return (score_final)
end

@view
func play_one_round_vs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(contract1 : felt, contract2 : felt) -> (result : (felt, felt)):
    alloc_locals

    let (prev_moves_arr : Move*) = alloc()

    let (m1) = IPlayerStrategy.execute_strategy(
        contract_address = contract1,
        prev_moves_len = 0,
        prev_moves = prev_moves_arr,
        move_num = 1,
        player_num = 1
    )
    let (m2) = IPlayerStrategy.execute_strategy(
        contract_address = contract2,
        prev_moves_len = 0,
        prev_moves = prev_moves_arr,
        move_num = 1,
        player_num = 2
    )
    let (scores) = table.read(m1, m2)
    return ((scores[0], scores[1]))
end