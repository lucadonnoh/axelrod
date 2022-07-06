%lang starknet
from src.strategy_manager import play_one_round_vs, play_vs, Score, play, register_strategy, get_player_id, get_player_address, get_player_points, create_tournament, match, matches_len, registered_players_len
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (get_caller_address)

@external
func test_one_round{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local strat_one : felt
    local strat_two : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_two.cairo").contract_address%}

    let (tournament_id) = create_tournament(cc=(2,2), cd=(-3,5), dc=(5,-3), dd=(-1,-1))

    let (scores) = play_one_round_vs(tournament_id, strat_one, strat_two)
    assert -3 = scores[0]
    assert 5 = scores[1]

    return ()
end

@external 
func test_ten_rounds{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    
    local strat_one : felt
    local strat_two : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_two.cairo").contract_address%}

    let (tournament_id) = create_tournament(cc=(2,2), cd=(-3,5), dc=(5,-3), dd=(-1,-1))

    let score : Score = play_vs(tournament_id, strat_one, strat_two, 10)

    assert -30 = score.player1_score
    assert 50 = score.player2_score

    return ()
end

@external 
func test_tit_tat{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    
    local strat_one : felt
    local strat_two : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_tit_tat.cairo").contract_address%}

    let (tournament_id) = create_tournament(cc=(2,2), cd=(-3,5), dc=(5,-3), dd=(-1,-1))

    let score : Score = play_vs(tournament_id, strat_one, strat_two, 10)

    assert 20 = score.player1_score
    assert 20 = score.player2_score

    return ()
end

@external 
func test_tit_tat_100_rounds{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    
    local strat_one : felt
    local strat_two : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_tit_tat.cairo").contract_address%}

    let (tournament_id) = create_tournament(cc=(2,2), cd=(-3,5), dc=(5,-3), dd=(-1,-1))

    let score : Score = play_vs(tournament_id, strat_one, strat_two, 100)

    assert 200 = score.player1_score
    assert 200 = score.player2_score

    return ()
end


@external
func test_register_and_play_with_two_strats{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    
    local strat_one : felt
    local strat_two : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_two.cairo").contract_address%}

    let (tournament_id) = create_tournament(cc=(2,2), cd=(-3,5), dc=(5,-3), dd=(-1,-1))

    let (caller1) = get_caller_address()
    let (prev_id1) = get_player_id(tournament_id, caller1)
    assert 0 = prev_id1
    let (player1_id) = register_strategy(tournament_id, strat_one)
    let (post_id1) = get_player_id(tournament_id, caller1)
    assert 1 = post_id1
    assert post_id1 = player1_id

    %{ stop_prank_callable = start_prank(123) %} # change the caller to addr 123
    let (caller2) = get_caller_address()
    let (prev_id2) = get_player_id(tournament_id, caller2)
    assert 0 = prev_id2
    let (player2_id) = register_strategy(tournament_id, strat_two)
    let (post_id2) = get_player_id(tournament_id, caller2)
    assert 2 = post_id2
    assert post_id2 = player2_id
    %{ stop_prank_callable() %}

    let (prev_score1) = get_player_points(tournament_id, player1_id)
    assert 0 = prev_score1
    let (prev_score2) = get_player_points(tournament_id, player2_id)
    assert 0 = prev_score2

    play(tournament_id)

    let (n_matches) = matches_len.read(tournament_id)
    assert 1 = n_matches

    let (m) = match.read(tournament_id, 1)

    # note: the order is inverted because the play call is backwards
    assert caller1 = m.player2
    assert caller2 = m.player1

    let (post_score1) = get_player_points(tournament_id, player1_id)
    assert -30 = post_score1
    let (post_score2) = get_player_points(tournament_id, player2_id)
    assert 50 = post_score2

    let score = m.score
    let s1 = score.player1_score
    let s2 = score.player2_score

    # inverted for the same reason as above
    assert post_score1 = s2
    assert post_score2 = s1

    return ()
end

@external
func test_register_and_play_with_three_strats{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    
    local strat_one : felt
    local strat_two : felt
    local strat_three : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_two.cairo").contract_address%}
    %{ids.strat_three = deploy_contract("./src/player_strategy_two.cairo").contract_address%}

    let (tournament_id) = create_tournament(cc=(2,2), cd=(-3,5), dc=(5,-3), dd=(-1,-1))

    let (player1_id) = register_strategy(tournament_id, strat_one)

    %{ stop_prank_callable = start_prank(123) %}
    let (player2_id) = register_strategy(tournament_id, strat_two)
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(456) %}
    let (player3_id) = register_strategy(tournament_id, strat_three)
    %{ stop_prank_callable() %}

    play(tournament_id)

    let (n_matches) = matches_len.read(tournament_id)
    assert 3 = n_matches

    let (score1) = get_player_points(tournament_id, player1_id)
    assert -60 = score1 # -30 + -30
    let (score2) = get_player_points(tournament_id, player2_id)
    assert 40 = score2  #  50 + -10
    let (score3) = get_player_points(tournament_id, player3_id)
    assert 40 = score3  #  50 + -10

    return ()
end

@external
func test_failing_create_strategy_for_uninitialized_tournament{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    
    local strat_one : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}

    %{ expect_revert(error_message="The tournament is not active") %}
    let (player_id) = register_strategy(1, strat_one)

    return ()
end

@external
func test_failing_play_uninitialized_tournament{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    
    %{ expect_revert(error_message="The tournament is not active") %}
    play(1)

    return ()
end

@external
func test_two_tournaments{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    
    local strat_one : felt
    local strat_two : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_two.cairo").contract_address%}

    let (tournament_id1) = create_tournament(cc=(2,2), cd=(-3,5), dc=(5,-3), dd=(-1,-1))
    let (tournament_id2) = create_tournament(cc=(2,2), cd=(-5,8), dc=(8,-5), dd=(-1,-1))
    
    let (t1_player1_id) = register_strategy(tournament_id1, strat_one)
    %{ stop_prank_callable = start_prank(123) %}
    let (t1_player2_id) = register_strategy(tournament_id1, strat_two)
    %{ stop_prank_callable() %}

    let (t2_player1_id) = register_strategy(tournament_id2, strat_one)
    
    %{ stop_prank_callable = start_prank(123) %}
    let (t2_player2_id) = register_strategy(tournament_id2, strat_two)
    %{ stop_prank_callable() %}

    play(tournament_id1)
    play(tournament_id2)

    let (t1_score1) = get_player_points(tournament_id1, t1_player1_id)
    assert -30 = t1_score1
    let (t1_score2) = get_player_points(tournament_id1, t1_player2_id)
    assert 50 = t1_score2

    let (t2_score1) = get_player_points(tournament_id2, t2_player1_id)
    assert -50 = t2_score1
    let (t2_score2) = get_player_points(tournament_id2, t2_player2_id)
    assert 80 = t2_score2

    return ()
end

@external
func test_n_matches{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals
    
    local strat_one : felt
    local strat_two : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_two.cairo").contract_address%}

    let (tournament_id) = create_tournament(cc=(2,2), cd=(-3,5), dc=(5,-3), dd=(-1,-1))
    
    let (player1_id) = register_strategy(tournament_id, strat_one)
    %{ stop_prank_callable = start_prank(123) %}
    let (player2_id) = register_strategy(tournament_id, strat_two)
    %{ stop_prank_callable() %}
    %{ stop_prank_callable = start_prank(456) %}
    let (player3_id) = register_strategy(tournament_id, strat_two)
    %{ stop_prank_callable() %}
    %{ stop_prank_callable = start_prank(789) %}
    let (player4_id) = register_strategy(tournament_id, strat_one)
    %{ stop_prank_callable() %}

    play(tournament_id)

    let (n_matches) = matches_len.read(tournament_id)
    let (n_players) = registered_players_len.read(tournament_id)
    let (calc) = calc_n_matches(n_players)
    assert calc = n_matches

    return ()
end

func calc_n_matches{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(
    n_players : felt
) -> (n_matches : felt):
    let res = n_players * (n_players - 1) / 2
    return (res)
end