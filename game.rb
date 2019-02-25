require_relative 'display'
require_relative 'humanplayer'

class Game
    def initialize
        @board = Board.new
        @display = Display.new(@board)
        @players = { :white => HumanPlayer.new(:white, @display), :black => HumanPlayer.new(:black, @display) }
        @current_player = :white
        system('clear')
        if %x( printenv TERM_PROGRAM ).chomp != "iTerm.app"
            puts "Sadly, it appears you are not running iTerm2, and so\ndo not have true color support. For best results,\nplease run in iTerm2. If you are positive your\nterminal can support true color mode or would like\nto try, press 'tab' at any time to switch modes.\nReverting to 256 color mode...\n\n"
            Paint.mode = 256
        end
        puts "Welcome to Terminal Chess! At any point,\npress ctrl-s to save your game,\nor ctrl-l to load a saved game.\nPress ctrl-c to exit.\nPress any key to continue."
        @display.cursor.read_char
    end

    def play
        while !game_over?
            @players[@current_player].make_move(@board)
            (@current_player == :white) ? (@current_player = :black) : (@current_player = :white)
        end
        system('clear')
        @display.render
        puts "White has been checkmated! Congratulations, black." if @board.checkmate?(:white)
        puts "Black has been checkmated! Congratulations, white." if @board.checkmate?(:black)
        puts "White can no longer move and the game is stalemated!" if @board.stalemate?(:white)
        puts "Black can no longer move and the game is stalemated!" if @board.stalemate?(:black)
        puts "There is insufficient material to mate and the game is drawn." if @board.draw?
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

    def game_over?
        @board.checkmate?(:white) || @board.checkmate?(:black) || @board.stalemate?(:white) || @board.stalemate?(:black) || @board.draw?
    end

    def game_over_reason
        return "White has been checkmated! Congratulations, black." if @board.checkmate?(:white)
        return "Black has been checkmated! Congratulations, white." if @board.checkmate?(:black)
        return "White can no longer move and the game is stalemated!" if @board.stalemate?(:white)
        return "Black can no longer move and the game is stalemated!" if @board.stalemate?(:black)
        return "There is insufficient material to mate and the game is drawn." if @board.draw?
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