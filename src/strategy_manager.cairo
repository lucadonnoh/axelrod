%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_caller_address)
from starkware.cairo.common.bool import TRUE, FALSE

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

struct Match:
    member player1 : felt
    member player2 : felt
    member score : Score
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
func tournaments_len() -> (len : felt):
end

# when created, a tournament is active i.e. new strategies can be added
# when a tournament is played it becomes unactive
# also useful to prevent adding strategies to uninitialized tournaments
@storage_var
func is_active(tournament_id : felt) -> (b : felt):
end

@storage_var
func table(tournament_id : felt, move1 : felt, move2 : felt) -> (score : (felt, felt)):
end

@storage_var
func strategy_contracts(tournament_id : felt, player_id : felt) -> (strategy_address : felt):
end

@storage_var
func player_id_to_address(tournament_id : felt, player_id : felt) -> (player_address : felt):
end

@storage_var
func player_address_to_id(tournament_id : felt, player_address : felt) -> (player_id : felt):
end

@storage_var
func registered_players_len(tournament_id : felt) -> (len : felt):
end

@storage_var
func points(tournament_id : felt, player_id : felt) -> (points : felt):
end

@storage_var
func match(tournament_id : felt, match_id : felt) -> (match : Match):
end

@storage_var
func matches_len(tournament_id : felt) -> (len : felt):
end

@storage_var
func tournament_owner(tournament_id : felt) -> (owner : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():

    return ()
end

@external
func create_tournament{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    cc : (felt, felt), cd : (felt, felt), dc : (felt, felt), dd : (felt, felt)
) -> (tournament_id : felt):
    alloc_locals

    let (curr_id) = tournaments_len.read()
    let tournament_id = curr_id + 1
    tournaments_len.write(tournament_id)

    table.write(tournament_id, COOPERATE, COOPERATE, cc)
    table.write(tournament_id, COOPERATE, DEFECT, cd)
    table.write(tournament_id, DEFECT, COOPERATE, dc)
    table.write(tournament_id, DEFECT, DEFECT, dd)

    is_active.write(tournament_id, TRUE)

    let (owner) = get_caller_address()
    tournament_owner.write(tournament_id, owner)

    return (tournament_id)
end

@view
func get_player_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt, player_address : felt
) -> (player_id : felt):
    return player_address_to_id.read(tournament_id, player_address)
end

@view
func get_player_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt, player_id : felt
) -> (player_address : felt):
    return player_id_to_address.read(tournament_id, player_id)
end

@view
func get_player_points{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt, player_id : felt
) -> (points : felt):
    return points.read(tournament_id, player_id)
end

@external
func register_strategy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt, strategy_address : felt
) -> (player_id : felt):

    let (b) = is_active.read(tournament_id)

    with_attr error_message(
            "The tournament is not active"):
        assert TRUE = b
    end

    let (caller_address) = get_caller_address()

    let (player_id) = player_address_to_id.read(tournament_id, caller_address)
    # if already registered, overwrite strategy
    let (is_registered) = is_not_zero(player_id)
    if is_registered == TRUE:
        strategy_contracts.write(tournament_id, player_id, strategy_address)
        return (player_id)
    end

    let (curr_id) = registered_players_len.read(tournament_id)
    let player_id = curr_id + 1
    registered_players_len.write(tournament_id, player_id)

    player_id_to_address.write(tournament_id, player_id, caller_address)
    player_address_to_id.write(tournament_id, caller_address, player_id)

    strategy_contracts.write(tournament_id, player_id, strategy_address)
    return (player_id)
end

@external
func play{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt
) -> ():

    let (b) = is_active.read(tournament_id)

    with_attr error_message(
            "The tournament is not active"):
        assert TRUE = b
    end

    let (owner) = tournament_owner.read(tournament_id)
    let (caller) = get_caller_address()
    with_attr error_message(
            "Only the owner can start the tournament"):
        assert owner = caller
    end

    is_active.write(tournament_id, FALSE)
    
    let (tot_players) = registered_players_len.read(tournament_id)

    _recursive_play(tournament_id, tot_players - 1, tot_players)

    return ()

end

func _recursive_play{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt, against : felt, num_players : felt
) -> ():
    alloc_locals

    if num_players == 1:
        return ()
    end

    if against == 0:
        return _recursive_play(tournament_id, num_players - 2, num_players - 1)
    end

    let player1_id = num_players
    let player2_id = against

    let (strat1) = strategy_contracts.read(tournament_id, player1_id)
    let (strat2) = strategy_contracts.read(tournament_id, player2_id)

    let (old_points1) = points.read(tournament_id, player1_id)
    let (old_points2) = points.read(tournament_id, player2_id)

    let (score) = play_vs(tournament_id, strat1, strat2, NUM_ROUNDS)

    let (curr_match_id) = matches_len.read(tournament_id)
    let match_id = curr_match_id + 1
    matches_len.write(tournament_id, match_id)

    let (player1_address) = player_id_to_address.read(tournament_id, player1_id)
    let (player2_address) = player_id_to_address.read(tournament_id, player2_id)

    let m = Match(player1_address, player2_address, score)
    match.write(tournament_id, match_id, m)

    let new_points1 = old_points1 + score.player1_score
    let new_points2 = old_points2 + score.player2_score

    points.write(tournament_id, player1_id, new_points1)
    points.write(tournament_id, player2_id, new_points2)

    return _recursive_play(tournament_id, against - 1, num_players)

end

@view
func play_vs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt,
    strategy1_address : felt, 
    strategy2_address : felt, 
    num_rounds : felt
) -> (result : Score):
    alloc_locals

    let scores = Score(0,0)
    let (moves : Move*) = alloc()
    let (score_final) = _recurse_play_vs(tournament_id, strategy1_address, strategy2_address, num_rounds, 0, moves, 0, scores)

    return (score_final)
end

func _recurse_play_vs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt,
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

    let (scores_round) = table.read(tournament_id, m1, m2)
    let score_nxt_p1 = scores.player1_score + scores_round[0]
    let score_nxt_p2 = scores.player2_score + scores_round[1]

    let score_nxt = Score(score_nxt_p1, score_nxt_p2)

    let round_move = Move(m1, m2)
    assert moves[idx] = round_move

    let (score_final) = _recurse_play_vs(
        tournament_id,
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
func play_one_round_vs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tournament_id : felt, contract1 : felt, contract2 : felt
) -> (result : (felt, felt)):
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
    let (scores) = table.read(tournament_id, m1, m2)
    return ((scores[0], scores[1]))
end