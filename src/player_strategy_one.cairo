%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

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
    return (0)
end