%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

const COOPERATE = 0
const DEFECT = 1

struct Move:
    member player1_move: felt
    member player2_move: felt
end

@external
@view 
func execute_strategy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    prev_moves_len:felt, 
    prev_moves:Move*, 
    move_num:felt,
    player_num:felt, 
) -> (strategy: felt):
    #Move Number Starts at 0
    if move_num == 0:
        return (COOPERATE)
    end

    if player_num==1:
        return (prev_moves[move_num-1].player2_move)
    else:
        return (prev_moves[move_num-1].player1_move)
    end

end