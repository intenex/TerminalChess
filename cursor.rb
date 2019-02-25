require "io/console"

KEYMAP = {
  " " => :space,
  "h" => :left,
  "j" => :down,
  "k" => :up,
  "l" => :right,
  "w" => :up,
  "a" => :left,
  "s" => :down,
  "d" => :right,
  "\t" => :tab,
  "\r" => :return,
  "\n" => :newline,
  "\e" => :escape,
  "\e[A" => :up,
  "\e[B" => :down,
  "\e[C" => :right,
  "\e[D" => :left,
  "\177" => :backspace,
  "\004" => :delete,
  "\u0003" => :ctrl_c,
  "\u0013" => :ctrl_s,
  "\f" => :ctrl_l
}

MOVES = {
  left: [0, -1],
  right: [0, 1],
  up: [-1, 0],
  down: [1, 0]
}

class Cursor

  attr_reader :cursor_pos, :board, :selected
  attr_accessor :start_pos, :end_pos

  def initialize(cursor_pos, board)
    @cursor_pos = cursor_pos
    @board = board
    @selected = false
    @start_pos = Array.new
    @end_pos = Array.new
  end

  def get_input(color)
    key = KEYMAP[read_char]
    handle_key(key, color)
  end

  private

  def read_char
    STDIN.echo = false # stops the console from printing return values # whoah this is awesome love it

    STDIN.raw! # in raw mode data is given as is to the program--the system
                 # doesn't preprocess special characters such as control-c

    input = STDIN.getc.chr # STDIN.getc reads a one-character string as a
                             # numeric keycode. chr returns a string of the
                             # character represented by the keycode.
                             # (e.g. 65.chr => "A") # nice

    if input == "\e" then
      input << STDIN.read_nonblock(3) rescue nil # read_nonblock(maxlen) reads
                                                   # at most maxlen bytes from a
                                                   # data stream; it's nonblocking,
                                                   # meaning the method executes
                                                   # asynchronously; it raises an
                                                   # error if no data is available,
                                                   # hence the need for rescue

      input << STDIN.read_nonblock(2) rescue nil
    end

    STDIN.echo = true # the console prints return values again # ah have to manually set this back
    STDIN.cooked! # the opposite of raw mode :)

    return input
  end

  class SaveGameEscape < StandardError
  end

  class LoadGameEscape < StandardError
  end

  def handle_key(key, color)
    case key
    when :return, :space
      row, col = @cursor_pos
      if @board.grid[row][col].color == color
        @selected = true
        @start_pos = @cursor_pos
      elsif (@board.grid[row][col].color != color) && @selected
        @end_pos = @cursor_pos
        @selected = false
      end
      @cursor_pos
    when :left, :right, :up, :down
      update_pos(MOVES[key])
      nil
    when :ctrl_s
      raise SaveGameEscape
    when :ctrl_l
      raise LoadGameEscape
    when :ctrl_c
      Process.exit(0)
    end
  end

  def update_pos(diff)
    transposed_pos = [@cursor_pos, diff].transpose.map(&:sum)
    @board.valid_pos?(transposed_pos) ? (@cursor_pos = transposed_pos) : nil
  end
end