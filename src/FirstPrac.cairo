%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

const COOPERATE = 0
const DEFECT = 1

struct Move:
    member player1_move : felt
    member player2_move : felt
end

struct Transition:
    member move : felt
    member nxt_state : felt
end

@storage_var
func state(id : felt, adv_move : felt) -> (t : Transition):
end

@storage_var
func current_state() -> (state_id : felt):
end

@storage_var
func first_move() -> (move : felt):
end

# personalize
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    first_move.write(COOPERATE)

    state.write(0, COOPERATE, Transition(COOPERATE, 1))
    state.write(0, DEFECT,    Transition(COOPERATE, 2))
    state.write(1, COOPERATE, Transition(COOPERATE, 0))
    state.write(1, DEFECT,    Transition(COOPERATE, 2))
    state.write(2, COOPERATE, Transition(COOPERATE, 1))
    state.write(2, DEFECT,    Transition(DEFECT,    3))
    state.write(3, COOPERATE, Transition(COOPERATE, 4))
    state.write(3, DEFECT,    Transition(DEFECT,    5))
    state.write(4, COOPERATE, Transition(COOPERATE, 1))
    state.write(4, DEFECT,    Transition(DEFECT,    2))
    state.write(5, COOPERATE, Transition(COOPERATE, 1))
    state.write(5, DEFECT,    Transition(DEFECT,    6))
    state.write(6, COOPERATE, Transition(DEFECT,    3))
    state.write(6, DEFECT,    Transition(DEFECT,    7))
    state.write(7, COOPERATE, Transition(COOPERATE, 3))
    state.write(7, DEFECT,    Transition(DEFECT,    7))

    return ()
end

@external
func execute_strategy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    prev_moves_len : felt, 
    prev_moves : Move*, 
    move_num : felt,
    player_num : felt,
) -> (strategy : felt):
    alloc_locals

    if move_num == 0:
        let (m) = first_move.read()
        return (m)
    end
    
    if player_num == 1:
        let adv_move = prev_moves[move_num - 1].player2_move
        let (state_id) = current_state.read()
        let (t) = state.read(state_id, adv_move)
        let new_state = t.nxt_state
        current_state.write(new_state)
        return (t.move)
    else:
        let adv_move = prev_moves[move_num - 1].player1_move
        let (state_id) = current_state.read()
        let (t) = state.read(state_id, adv_move)
        let new_state = t.nxt_state
        current_state.write(new_state)
        return (t.move)
    end

end




