%lang starknet
from src.v0 import table, play_one_round
from starkware.cairo.common.cairo_builtins import HashBuiltin

const COOPERATE = 0
const DEFECT = 1

@external
func test_one_round{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}():
    let move1 = COOPERATE
    let move2 = COOPERATE
    let (scores) = play_one_round(move1, move2)
    assert 2 = scores[0]
    assert 2 = scores[1]

    let move1 = COOPERATE
    let move2 = DEFECT
    let (scores) = play_one_round(move1, move2)
    assert -3 = scores[0]
    assert 5 = scores[1]

    let move1 = DEFECT
    let move2 = COOPERATE
    let (scores) = play_one_round(move1, move2)
    assert 5 = scores[0]
    assert -3 = scores[1]

    let move1 = DEFECT
    let move2 = DEFECT
    let (scores) = play_one_round(move1, move2)
    assert -1 = scores[0]
    assert -1 = scores[1]

    return ()
end
