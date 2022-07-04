%lang starknet
from src.strategy_manager import play_one_round_vs, play_vs, Score
from starkware.cairo.common.cairo_builtins import HashBuiltin

@external
func test_one_round{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    alloc_locals

    local strat_one:felt
    local strat_two:felt

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
    
    local strat_one:felt
    local strat_two:felt

    %{ids.strat_one = deploy_contract("./src/player_strategy_one.cairo").contract_address%}
    %{ids.strat_two = deploy_contract("./src/player_strategy_two.cairo").contract_address%}

    let score:Score = play_vs(strat_one, strat_two, 10)

    assert -30 = score.player1_score
    assert 50 = score.player2_score

    return ()
end