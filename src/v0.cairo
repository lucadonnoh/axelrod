%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin

const COOPERATE = 0
const DEFECT = 1

@storage_var
func table(move1 : felt, move2 : felt) -> (score : (felt, felt)):
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
func play_one_round{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(move1 : felt, move2 : felt) -> (result : (felt, felt)):
    let (scores) = table.read(move1, move2)
    return ((scores[0], scores[1]))
end
