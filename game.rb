require_relative 'display'
require_relative 'humanplayer'

class Game
    def initialize
        @board = Board.new
        @display = Display.new(@board)
        @players = { :white => HumanPlayer.new(:white, @display), :black => HumanPlayer.new(:black, @display) }
        @current_player = :white
        system('clear')
        if %x( printenv TERM_PROGRAM ).chomp != "iTerm.app" # only iTerm2 displays true colors so far as you can tell so otherwise set to 256 colors unless you find other true color terminals --> printenv TERM_PROGRAM is a shell command that returns the name of the terminal app currently running, and you run shell commands in Ruby with the %x() shorthand which is pretty amazing as per https://stackoverflow.com/questions/2232/calling-shell-commands-from-ruby and printenv here https://www.computerhope.com/unix/printenv.htm thank god Paint has the 256 mode
            puts "Sadly, it appears you are not running iTerm2, and so\ndo not have true color support. For best results,\nplease run in iTerm2. Reverting to 256 color mode...\n\n"
            Paint.mode = 256
        end
        puts "Welcome to chess! At any point,\npress ctrl-s to save your game,\nor ctrl-l to load a saved game.\nPress ctrl-c to exit.\nPress any key to continue." # initialization message so it doesn't show up again when the game is played
        @display.cursor.read_char # just lets the player enter any key to move forward in the game
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