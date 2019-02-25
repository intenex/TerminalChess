require 'singleton'

module Slidable
    def moves
        directions = self.move_dirs
        row, col = @pos
        possible_moves = Array.new
        possible_moves += straight_slide(row, col) if directions.include?(:straight)
        possible_moves += diagonal_slide(row, col) if directions.include?(:diagonal)
        possible_moves
    end
end

def diagonal_slide(row, col)
    (row <= col) ? (smaller, larger = row, col) : (smaller, larger = col, row)
    nw = check_blocking_pieces((1..smaller).map { |offset| [row-offset, col-offset] })
    ne = check_blocking_pieces((1..(7-row)).map { |offset| [row+offset, col-offset] if ((col-offset) >= 0) }.compact)
    sw = check_blocking_pieces((1..(7-col)).map { |offset| [row-offset, col+offset] if ((row-offset) >= 0) }.compact)
    se = check_blocking_pieces((1..(7-larger)).map { |offset| [row+offset, col+offset] })
    (nw + ne + sw + se)
end

def straight_slide(row, col)
    up = check_blocking_pieces((0...row).map { |new_r| [new_r, col] }.reverse)
    down = check_blocking_pieces((row+1..7).map { |new_r| [new_r, col] })
    left = check_blocking_pieces((0...col).map { |new_c| [row, new_c] }.reverse)
    right = check_blocking_pieces((col+1..7).map { |new_c| [row, new_c] })
    (up + down + left + right)
end

def check_blocking_pieces(positions)
    positions.each_with_index do |move, index|
        piece = @board.grid[move[0]][move[1]]
        if !piece.is_a?(NullPiece)
            piece.color == self.color ? (return positions.slice(0...index)) : (return positions.slice(0..index))
        end
    end
end

module Stepable
    def moves
        offsets = move_diffs
        raw_move_pos = offsets.map { |offset| [offset, @pos].transpose.map(&:sum) }
        valid_pos = raw_move_pos.select do |p|
            if (p[0] >= 0) && (p[0] <= 7) && (p[1] >= 0) && (p[1] <= 7)
                piece = @board.grid[p[0]][p[1]]
                true if piece.is_a?(NullPiece) || piece.color != self.color
            end
        end
        if self.is_a?(King) && !self.moved
            queen_offsets = [[0, -1], [0, -2], [0, -3], [0, -4]]
            king_offsets = [[0, 1], [0, 2], [0, 3]]
            valid_pos << @castle_pos[0] if check_offsets(queen_offsets)
            valid_pos << @castle_pos[1] if check_offsets(king_offsets)
        end
        valid_pos
    end

    def check_offsets(offsets)
        offset_pos = offsets.map { |offset| [offset, @pos].transpose.map(&:sum) }
        offsets_empty = offset_pos[0...-1].all? { |position| (row, col = position); @board.grid[row][col].is_a?(NullPiece) }
        rook_row, rook_col = offset_pos[-1]
        maybe_rook = @board.grid[rook_row][rook_col]
        offsets_empty && maybe_rook.is_a?(Rook) && !maybe_rook.moved
    end

end

class Piece
    attr_reader :color
    attr_accessor :board, :pos

    def initialize(color, board, pos)
        @color = color
        @board = board
        @pos = pos
    end

    def to_s; @symbol.to_s end

    def valid_moves
        all_moves = moves
        all_moves.reject { |move| move_into_check?(move) }
    end

    def move_into_check?(end_pos) 
        dup_board = @board.dup
        dup_board.move_piece!(@pos, end_pos)
        dup_board.in_check?(@color)
    end

end

class Pawn < Piece
    attr_accessor :moved
    
    def initialize(color, board, pos); super; @symbol = :♙; @moved = false end

    def moves
        possible_moves = Array.new
        new_row = @pos[0] + forward_dir
        if new_row >= 0 && new_row <= 7
            f_steps, s_attacks = forward_steps(new_row), side_attacks(new_row)
            possible_moves += f_steps if !f_steps.empty?
            possible_moves += s_attacks if !s_attacks.empty?
            possible_moves
        else
            []
        end
    end

    private
    def forward_dir
        (self.color == :white) ? -1 : 1
    end

    def at_start_row?
        (self.color == :white) ? (start_row = 6) : (start_row = 1)
        @pos[0] == start_row
    end

    def forward_steps(new_row)
        f_steps = Array.new
        one_step = [new_row, @pos[1]] 
        two_step_row = new_row + forward_dir
        if (two_step_row >= 0) && (two_step_row <= 7)
            (f_steps << [two_step_row, @pos[1]]) if (at_start_row? && @board.grid[two_step_row][@pos[1]].is_a?(NullPiece) && @board.grid[new_row][@pos[1]].is_a?(NullPiece))
        end
        f_steps << one_step if @board.grid[new_row][@pos[1]].is_a?(NullPiece)
        f_steps
    end

    def side_attacks(new_row)
        s_attacks = Array.new
        left = [new_row, (@pos[1]-1)] if ((@pos[1]-1 >= 0) && (@pos[1]-1 <= 7))
        right = [new_row, (@pos[1]+1)] if ((@pos[1]+1 >= 0) && (@pos[1]+1 <= 7))
        (en_passant_pawn = @board.grid[@board.en_passant[0][0]][@board.en_passant[0][1]]) if !@board.en_passant.empty?
        if left
            l_piece = @board.grid[left[0]][left[1]]
            (s_attacks << left) if (!l_piece.is_a?(NullPiece) && (l_piece.color != self.color)) || ((@board.en_passant[1] == left) && (en_passant_pawn.color != self.color))
        end
        if right
            r_piece = @board.grid[right[0]][right[1]]
            (s_attacks << right) if (!r_piece.is_a?(NullPiece) && (r_piece.color != self.color)) || ((@board.en_passant[1] == right) && (en_passant_pawn.color != self.color))
        end
        s_attacks
    end
end

class King < Piece
    include Stepable

    attr_accessor :moved
    attr_reader :castle_pos, :rook_start_pos, :rook_end_pos

    def initialize(color, board, pos)
        super
        @symbol = :♚
        @moved = false
        if color == :white
            @castle_pos = [[7, 2], [7, 6]]
            @rook_start_pos = [[7, 0], [7,7]]
            @rook_end_pos = [[7, 3], [7, 5]]
        else
            @castle_pos = [[0, 2], [0, 6]]
            @rook_start_pos = [[0, 0], [0, 7]]
            @rook_end_pos = [[0, 3], [0, 5]]
        end
    end

    def move_diffs
        [[-1, -1], [0, -1], [1, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0]]
    end

end

class Queen < Piece
    include Slidable

    def initialize(color, board, pos); super; @symbol = :♛ end
    def move_dirs; [:straight, :diagonal] end
end

class Rook < Piece
    include Slidable

    attr_accessor :moved

    def initialize(color, board, pos); super; @symbol = :♜; @moved = false end

    def move_dirs; [:straight] end
end

class Bishop < Piece
    include Slidable

    attr_reader :b_color

    def initialize(color, board, pos)
        super
        @symbol = :♝
        if @pos[0] == 0
            (@pos[1] % 2 == 0) ? (@b_color = :white) : (@b_color = :black)
        else
            (@pos[1] % 2 == 0) ? (@b_color = :black) : (@b_color = :white)
        end
    end

    def move_dirs; [:diagonal] end
end

class Knight < Piece
    include Stepable

    def initialize(color, board, pos); super; @symbol = :♞ end
    def move_diffs
        [[-2, -1], [-1, -2], [1, -2], [2, -1], [2, 1], [1, 2], [-1, 2], [-2, 1]]
    end
end

class NullPiece < Piece
    include Singleton

    def initialize; @color = :none; @symbol = :" " end

    def moves; [] end
end