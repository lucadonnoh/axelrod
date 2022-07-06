%lang starknet
from src.strategy_manager import play_one_round_vs, play_vs, Score, play, register_strategy, get_player_id, get_player_address, get_player_points
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (get_caller_address)

@external
func test_one_round{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local strat_one : felt
    local strat_two : felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_two.cairo").contract_address%}

    let (scores) = play_one_round_vs(strat_one, strat_two)
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

    let score : Score = play_vs(strat_one, strat_two, 10)

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

    let score : Score = play_vs(strat_one, strat_two, 10)

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

    let score : Score = play_vs(strat_one, strat_two, 100)

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

    let (caller1) = get_caller_address()
    let (prev_id1) = get_player_id(caller1)
    assert 0 = prev_id1
    register_strategy(strat_one)
    let (post_id1) = get_player_id(caller1)
    assert 1 = post_id1

    %{ stop_prank_callable = start_prank(123) %} # change the caller to addr 123
    let (caller2) = get_caller_address()
    let (prev_id2) = get_player_id(caller2)
    assert 0 = prev_id2
    register_strategy(strat_two)
    let (post_id2) = get_player_id(caller2)
    assert 2 = post_id2
    %{ stop_prank_callable() %}

    let (prev_score1) = get_player_points(post_id1)
    assert 0 = prev_score1
    let (prev_score2) = get_player_points(post_id2)
    assert 0 = prev_score2

    play()

    let (post_score1) = get_player_points(post_id1)
    assert -30 = post_score1
    let (post_score2) = get_player_points(post_id2)
    assert 50 = post_score2

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

    register_strategy(strat_one)   # player 1

    %{ stop_prank_callable = start_prank(123) %}
    register_strategy(strat_two)   # player 2
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(456) %}
    register_strategy(strat_three) # player 3
    %{ stop_prank_callable() %}

    play()

    let (score1) = get_player_points(1)
    assert -60 = score1 # -30 + -30
    let (score2) = get_player_points(2)
    assert 40 = score2  #  50 + -10
    let (score3) = get_player_points(3)
    assert 40 = score3  #  50 + -10

    return ()
end

