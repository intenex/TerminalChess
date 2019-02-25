require_relative 'display'
require_relative 'humanplayer'

class Game
    def initialize
        @board = Board.new
        @display = Display.new(@board)
        @players = { :white => HumanPlayer.new(:white, @display), :black => HumanPlayer.new(:black, @display) }
        @current_player = :white
        puts "Welcome to chess! At any point,\npress ctrl-s to save your game,\nor ctrl-l to load a saved game.\nPress ctrl-c to exit."
        sleep(3)
    end

    def play
        while !@board.checkmate?(:white) && !@board.checkmate?(:black)
            @players[@current_player].make_move(@board)
            (@current_player == :white) ? (@current_player = :black) : (@current_player = :white)
        end
        system('clear')
        @display.render
        @board.checkmate?(:white) ? (puts "White has been checkmated! Congratulations, black.") : (puts "Black has been checkmated! Congratulations, white.")
    rescue Cursor::SaveGameEscape
        begin
            save_game
        rescue Game::GameReturnEscape
            self.play
        rescue => e
            puts "#{e}\nHmm, something went wrong. Please try again."
            sleep(1)
            retry
        end
    rescue Cursor::LoadGameEscape
        begin
            load_game
        rescue Game::GameReturnEscape 
            self.play
        rescue => e
            puts "#{e}\nSorry, that file could not be loaded. Please try again."
            sleep(1)
            retry
        end
    end

    class GameReturnEscape < StandardError
    end

    def save_game
        puts "Please enter the filename you would like to save to,\nor type 'back' to return to your game."
        filename = gets.chomp.downcase
        if filename == 'back'
            puts "Game not saved. Returning back..."
            sleep(1)
            raise GameReturnEscape
        end
        saved_game = Marshal.dump(self)
        IO.write(filename, saved_game)
        puts "Game successfully saved! Continuing on..."
        sleep(1)
        self.play
    end

    def load_game
        puts "Please enter the filename you would like to load from,\nor type 'back' to return to your game."
        filename = gets.chomp.downcase
        if filename == 'back'
            puts "Game not loaded. Returning back..."
            sleep(1)
            raise GameReturnEscape
        end
        loaded_file = Marshal.load(IO.read(filename))
        if loaded_file.is_a?(Game)
            puts "Game successfully loaded! Beginning play now..."
            sleep(1)
            loaded_file.play
        else
            raise ArgumentError.new("Loaded file is not a valid Game instance.")
        end
    end

end