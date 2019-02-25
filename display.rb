require 'paint'
require_relative 'board'
require_relative 'cursor'

class Display
    attr_reader :board, :cursor

    def initialize(board)
        @board = board
        @cursor = Cursor.new([0,0], @board)
    end

    def render
        @board.grid.each_with_index do |row, row_i|
            row.each_with_index do |col, col_i|
                if all_even?(row_i, col_i) || all_odd?(row_i, col_i)
                    print_piece(col, row_i, col_i, piece_color(col), "#9AB3C9")
                else
                    print_piece(col, row_i, col_i, piece_color(col), "#4A7190")
                end
            end
            puts
        end
        nil
    end

    def all_even?(row, col); (row % 2 == 0) && (col % 2 == 0) end
    def all_odd?(row, col); (row % 2 == 1) && (col % 2 == 1) end
    def cursor?(row, col); @cursor.cursor_pos == [row, col] end
    def prnt_cursor; @cursor.selected ? "#E56373" : "#FFD768" end
    def piece_color(piece); ((piece.color == :white) ? "#FFEED5" : "#063848") end
    def print_piece(piece, row_i, col_i, p_color, bg_color)
        if cursor?(row_i, col_i)
            p_color = prnt_cursor
            if piece.is_a?(NullPiece)
                @cursor.selected ? (piece = @board.grid[@cursor.start_pos[0]][@cursor.start_pos[1]]) : (piece = :៙)
            end
        end
        print Paint["#{piece.to_s} ", p_color, bg_color]
    end

end