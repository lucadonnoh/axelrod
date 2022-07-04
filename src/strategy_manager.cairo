%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_caller_address)

const COOPERATE = 0
const DEFECT = 1

struct Move:
    member player1_move:felt
    member player2_move:felt
end

struct Score:
    member player1_score:felt
    member player2_score:felt
end

@contract_interface
namespace IPlayerStrategy:
    func execute_strategy(
        prev_moves_len:felt, 
        prev_moves: Move*, 
        move_num:felt,
        player_num:felt,
    ) -> (strategy: felt):
    end
end

@storage_var
func table(move1 : felt, move2 : felt) -> (score : (felt, felt)):
end

@storage_var
func strategy_contracts(player_address:felt) -> (strategy_address:felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    table.write(COOPERATE, COOPERATE, (2, 2))
    table.write(COOPERATE, DEFECT, (-3, 5))
    table.write(DEFECT, COOPERATE, (5, -3))
    table.write(DEFECT, DEFECT, (-1, -1))

    return ()
end

@external
func register_strategy{syscall_ptr: felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(strategy_address:felt):
    let (caller_address) = get_caller_address()
    strategy_contracts.write(caller_address, strategy_address)
    return ()
end

@view
func play_vs{syscall_ptr: felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    strategy1_add:felt, 
    strategy2_add:felt, 
    num_rounds:felt
) -> (result:Score):
    alloc_locals

    let scores = Score(0,0)
    let (moves: Move*) = alloc()
    let (score_final) = _recurse_play_vs(strategy1_add, strategy2_add, num_rounds, 0, moves, 0, scores)
    return (score_final)
end

func _recurse_play_vs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    strategy1_add:felt,
    strategy2_add:felt,
    num_rounds:felt,
    moves_len:felt,
    moves:Move*,
    idx: felt,
    scores: Score
) -> (score_final: Score):
    alloc_locals

    if idx == num_rounds:
        return (scores)
    end

    let (m1) = IPlayerStrategy.execute_strategy(
        contract_address = strategy1_add,
        prev_moves_len = moves_len,
        prev_moves = moves,
        move_num = idx,
        player_num = 1
    )

    let (m2) = IPlayerStrategy.execute_strategy(
        contract_address = strategy2_add,
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

    let(score_final) = _recurse_play_vs(
        strategy1_add,
        strategy2_add,
        num_rounds,
        moves_len + 1,
        moves,
        idx + 1,
        score_nxt
    )

    return (score_final)
end

@view
func play_one_round_vs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(contract1:felt, contract2:felt) -> (result:(felt, felt)):
    alloc_locals

    let (prev_moves_arr:Move*) = alloc()

    let (strategy1) = IPlayerStrategy.execute_strategy(
        contract_address = contract1,
        prev_moves_len = 0,
        prev_moves = prev_moves_arr,
        move_num = 1,
        player_num = 1
    )
    let (strategy2) = IPlayerStrategy.execute_strategy(
        contract_address = contract2,
        prev_moves_len = 0,
        prev_moves = prev_moves_arr,
        move_num = 1,
        player_num = 2
    )
    let (scores) = table.read(strategy1, strategy2)
    return ((scores[0], scores[1]))
end