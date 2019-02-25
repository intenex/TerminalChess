class HumanPlayer
    def initialize(color, display)
        @color = color
        @display = display
    end

    def make_move(board)
        while @display.cursor.end_pos.empty?
            system('clear')
            @display.render
            puts "Current player: #{@color}"
            puts "Current selected piece: #{@display.cursor.start_pos}" if @display.cursor.selected
            @display.cursor.get_input(@color)
        end
        start_pos = @display.cursor.start_pos
        end_pos = @display.cursor.end_pos
        @display.cursor.start_pos = Array.new
        @display.cursor.end_pos = Array.new
        @display.board.move_piece(start_pos, end_pos)
    rescue ArgumentError => e
        puts e
        sleep(1)
        retry
    end
end