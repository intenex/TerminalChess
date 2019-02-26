require_relative 'piece'

class Board

    attr_accessor :grid
    attr_reader :en_passant

    def initialize
        @grid = Array.new(8) { Array.new(8) }
        @en_passant = Array.new
        set_back_row(:black, 0)
        set_pawns(:black, 1)
        set_back_row(:white, 7)
        set_pawns(:white, 6)
        (2..5).each { |row| @grid[row].each_index { |col| @grid[row][col] = NullPiece.instance } }
    end

    def move_piece(start_pos, end_pos)
        s_row, s_col = start_pos
        e_row, e_col = end_pos
        piece = @grid[s_row][s_col]
        if piece.is_a?(NullPiece)
            raise ArgumentError.new("There is no piece at that start position. Try again.")
        elsif !piece.moves.include?(end_pos)
            raise ArgumentError.new("The selected piece cannot move to that position. Try again.")
        elsif !piece.valid_moves.include?(end_pos)
            raise ArgumentError.new("That move would leave you in check! Try again.")
        elsif piece.is_a?(King) && piece.castle_pos.include?(end_pos) && !piece.moved 
            castle(piece, start_pos, end_pos)
        elsif piece.is_a?(Pawn) && ((end_pos[0] == 0) || (end_pos[0] == 7))
            begin
                pawn_promote(piece, start_pos, end_pos)
            rescue ArgumentError => e
                puts e
                retry
            end
        elsif !@en_passant.empty? && piece.is_a?(Pawn) && (end_pos == @en_passant[1]) && (piece.color != @grid[@en_passant[0][0]][@en_passant[0][1]].color)
            @grid[s_row][s_col], @grid[e_row][e_col] = NullPiece.instance, piece
            @grid[@en_passant[0][0]][@en_passant[0][1]] = NullPiece.instance
            piece.pos = end_pos
            @en_passant = Array.new
        else
            (@en_passant = Array.new) if !@en_passant.empty?
            if piece.is_a?(Pawn) && !piece.moved && ((end_pos[0] == 4) || (end_pos[0] == 3))
                (end_pos[0] == 4) ? (capture_pos = [5, e_col]) : (capture_pos = [2, e_col])
                @en_passant = [end_pos, capture_pos]
            end
            (piece.moved = true) if ((piece.is_a?(King) || piece.is_a?(Rook) || piece.is_a?(Pawn)) && !piece.moved)
            @grid[s_row][s_col], @grid[e_row][e_col] = NullPiece.instance, piece
            piece.pos = end_pos
        end
    end

    def move_piece!(start_pos, end_pos)
        s_row, s_col = start_pos
        e_row, e_col = end_pos
        piece = @grid[s_row][s_col]
        if !piece.is_a?(NullPiece)
            @grid[s_row][s_col], @grid[e_row][e_col] = NullPiece.instance, piece
            piece.pos = end_pos
        end
    end

    def dup
        new_board = Board.new
        new_board.grid.map!.with_index do |row, row_i|
            row.map.with_index do |col, col_i|
                old_piece = @grid[row_i][col_i]
                if old_piece.is_a?(NullPiece)
                    new_piece = old_piece
                else
                    new_piece = old_piece.clone
                    new_piece.board = new_board
                    new_piece
                end
            end
        end
        new_board
    end

    def valid_pos?(pos)
        row, col = pos
        row >= 0 && row < 8 && col >= 0 && col < 8
    end

    def in_check?(color)
        king_pos = []
        @grid.each { |row| row.each { |piece| (king_pos = piece.pos) if (piece.is_a?(King) && piece.color == color) } }
        @grid.any? { |row| row.any? { |piece| (piece.moves.include?(king_pos)) && (piece.color != color) } }
    end
    
    def checkmate?(color)
        (!@grid.any? { |row| row.any? { |piece| !piece.valid_moves.empty? && (piece.color == color) } }) && in_check?(color)
    end

    def stalemate?(color)
        (!@grid.any? { |row| row.any? { |piece| !piece.valid_moves.empty? && (piece.color == color) } }) && !in_check?(color)
    end

    def draw?
        draw = false
        if !any_piece?(:Queen) && !any_piece?(:Rook) && !any_piece?(:Bishop) && !any_piece?(:Knight) && !any_piece?(:Pawn)
            draw = true
        elsif !any_piece?(:Queen) && !any_piece?(:Rook) && !any_piece?(:Bishop) && !any_piece?(:Pawn) && (((how_many_color?(:Knight, :white) == 1) && (how_many_color?(:Knight, :black) == 0)) || ((how_many_color?(:Knight, :black) == 1) && (how_many_color?(:Knight, :white) == 0)))
            draw = true
        elsif !any_piece?(:Queen) && !any_piece?(:Rook) && !any_piece?(:Knight) && !any_piece?(:Pawn)
            draw = true if ((any_bishops_color?(:white) && !any_bishops_color?(:black)) || (any_bishops_color?(:black) && !any_bishops_color?(:white)))
        end
        draw
    end

    def any_piece?(type)
        @grid.any? { |row| row.any? { |piece| piece.is_a?(Object.const_get(type)) } }
    end

    def how_many_color?(type, color)
        counter = 0
        @grid.each { |row| row.each { |piece| counter += 1 if (piece.is_a?(Object.const_get(type)) && (piece.color == color)) } }
        counter
    end

    def any_bishops_color?(b_color)
        @grid.any? { |row| row.any? { |piece| (piece.is_a?(Bishop) && (piece.b_color == b_color)) } }
    end

    def castle(piece, start_pos, end_pos)
        raise ArgumentError.new("You cannot castle out of check. Try again.") if in_check?(piece.color)
        castle_side = piece.castle_pos.index(end_pos)
        raise ArgumentError.new("You cannot castle through an attacked position. Try again.") if piece.move_into_check?(piece.rook_end_pos[castle_side])
        s_row, s_col = start_pos
        e_row, e_col = end_pos
        r_s_row, r_s_col = piece.rook_start_pos[castle_side]
        r_e_row, r_e_col = piece.rook_end_pos[castle_side]
        rook = @grid[r_s_row][r_s_col]
        @grid[s_row][s_col], @grid[e_row][e_col] = NullPiece.instance, piece
        @grid[r_s_row][r_s_col], @grid[r_e_row][r_e_col] = NullPiece.instance, rook
        piece.pos = end_pos
        rook.pos = piece.rook_end_pos[castle_side]
    end

    def pawn_promote(piece, start_pos, end_pos)
        s_row, s_col = start_pos
        e_row, e_col = end_pos
        puts "Congratulations! Which piece would you like to promote to?\nQ for Queen, R for Rook, B for Bishop, and N for Knight."
        input = gets.chomp.downcase
        case input
        when "q"
            @grid[s_row][s_col], @grid[e_row][e_col] = NullPiece.instance, Queen.new(piece.color, self, end_pos)
        when "r"
            @grid[s_row][s_col], @grid[e_row][e_col] = NullPiece.instance, Rook.new(piece.color, self, end_pos)
        when "b"
            @grid[s_row][s_col], @grid[e_row][e_col] = NullPiece.instance, Bishop.new(piece.color, self, end_pos)
        when "n"
            @grid[s_row][s_col], @grid[e_row][e_col] = NullPiece.instance, Knight.new(piece.color, self, end_pos)
        else
            raise ArgumentError.new("That was not a valid promotion piece. Please try again.")
        end
    end

    private

    def set_back_row(color, row)
        pieces = [:Rook, :Knight, :Bishop, :Queen, :King, :Bishop, :Knight, :Rook] 
        @grid[row].each_index { |col| @grid[row][col] = Object.const_get(pieces.shift).new(color, self, [row, col]) }
    end

    def set_pawns(color, row)
        @grid[row].each_index { |col| @grid[row][col] = Pawn.new(color, self, [row, col]) }
    end
end