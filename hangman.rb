require 'json'

# --- Fallback para cores se a gem colorize não estiver disponível ---
begin
  require 'colorize'
rescue LoadError
  class String
    def red; self; end; def green; self; end; def yellow; self; end
    def blue; self; end; def cyan; self; end; def bold; self; end
  end
end

# --- Constantes de Arte e Interface ---
HANGMAN_ART = [
  <<~ART,
    +---+
    |   |
        |
        |
        |
        |
    =========
  ART
  <<~ART,
    +---+
    |   |
    O   |
        |
        |
        |
    =========
  ART
  <<~ART,
    +---+
    |   |
    O   |
    |   |
        |
        |
    =========
  ART
  <<~ART,
    +---+
    |   |
    O   |
   /|   |
        |
        |
    =========
  ART
  <<~ART,
    +---+
    |   |
    O   |
   /|\\  |
        |
        |
    =========
  ART
  <<~ART,
    +---+
    |   |
    O   |
   /|\\  |
   /    |
        |
    =========
  ART
  <<~ART,
    +---+
    |   |
    O   |
   /|\\  |
   / \\  |
        |
    =========
  ART
]

class Hangman
  # Configurações de Interface
  COL_RANK = 6
  COL_NAME = 15
  COL_SCORE = 8
  COL_ERRS = 8

  # Regras de Pontuação
  POINTS_PER_LETTER = 20
  POINTS_FOR_WIN    = 100
  HINT_PENALTY      = 50

  attr_reader :current_score

  def initialize(player_name, initial_score)
    @player_name = player_name
    @current_score = initial_score

    ranking_menu
    @category = choose_category
    @dictionary = load_dictionary
    @difficulty = choose_difficulty
    @secret_word = select_word.upcase
    @correct_letters = Array.new(@secret_word.length, "_")
    @wrong_attempts = 0
    @used_letters = []
  end

  def play
    while active?
      render_game
      guess = ask_for_guess
      process_guess(guess) if valid_guess?(guess)
    end
    finalize_game
  end

  private

  def clear_screen
    Gem.win_platform? ? system("cls") : system("clear")
  end

  def draw_line
    "+" + "-" * (COL_RANK + 2) + "+" + "-" * (COL_NAME + 2) + "+" + "-" * (COL_SCORE + 2) + "+" + "-" * (COL_ERRS + 2) + "+"
  end

  def difficulty_multiplier
    case @difficulty
    when 1 then 1.0
    when 2 then 1.5
    when 3 then 2.0
    else 1.0
    end
  end

  def ranking_menu
    loop do
      clear_screen
      puts "=== RANKING MENU === ".cyan.bold
      puts "Which difficulty ranking do you want to see?"
      puts "1. Easy"
      puts "2. Medium"
      puts "3. Hard"
      puts "4. Skip to Game"
      print "\nOption: "
      choice = gets.chomp.to_i

      case choice
      when 1 then display_ranking("Easy")
      when 2 then display_ranking("Medium")
      when 3 then display_ranking("Hard")
      when 4 then break
      else
        puts "❌ Invalid option!".red
        sleep 1
      end
    end
  end

  def display_ranking(filter_difficulty)
    clear_screen
    filename = "ranking.json"
    puts "🏆 --- #{filter_difficulty.upcase} RANKING --- 🏆".cyan.bold
    
    if !File.exist?(filename) || File.zero?(filename)
      puts "\nRanking is empty. Be the first to win!".yellow
    else
      file_content = File.read(filename)
      players = JSON.parse(file_content, symbolize_names: true)
      filtered_players = players.select { |p| p[:difficulty] == filter_difficulty }

      if filtered_players.empty?
        puts "\nNo records yet for #{filter_difficulty} difficulty.".yellow
      else
        top_players = filtered_players.sort_by { |p| -p[:score] }.first(5)

        puts draw_line.blue
        puts "| #{"RANK".center(COL_RANK)} | #{"PLAYER".center(COL_NAME)} | #{"SCORE".center(COL_SCORE)} | #{"ERRORS".center(COL_ERRS)} |".blue.bold
        puts draw_line.blue

        top_players.each_with_index do |p, i|
          medal = case i
                  when 0 then "🥇"
                  when 1 then "🥈"
                  when 2 then "🥉"
                  else " #{i + 1} "
                  end
          
          rank_cell  = medal.center(COL_RANK - 1)
          name_cell  = p[:name].to_s.ljust(COL_NAME)
          score_cell = p[:score].to_s.center(COL_SCORE)
          errs_cell  = p[:errors].to_s.center(COL_ERRS)

          puts "| #{rank_cell} | #{name_cell} | #{score_cell} | #{errs_cell} |".yellow
        end
        puts draw_line.blue
      end
    end
    print "\nPress ENTER to return to menu..."
    gets
  end

  def choose_category
    loop do
      clear_screen
      puts "=== CHOOSE CATEGORY ===".cyan.bold
      puts "1. Animals"
      puts "2. Countries"
      puts "3. Programming"
      print "\nChoice: "
      choice = gets.chomp.to_i

      case choice
      when 1 then return "animals"
      when 2 then return "countries"
      when 3 then return "programming"
      else
        puts "❌ Invalid option!".red
        sleep 1
      end
    end
  end

  def load_dictionary
    filename = "data/#{@category}.txt"
    if File.exist?(filename)
      words = File.read(filename).split.map(&:strip).reject(&:empty?)
      return words unless words.empty?
      ["RUBY"]
    else
      puts "❌ Error: Category file '#{filename}' not found!".red
      exit
    end
  end

  def choose_difficulty
    loop do
      clear_screen
      puts "=== CHOOSE DIFFICULTY ===".cyan.bold
      puts "1. Easy   (Up to 5 letters)"
      puts "2. Medium (6 to 10 letters)"
      puts "3. Hard   (More than 10 letters)"
      print "\nOption: "
      choice = gets.chomp.to_i
      return choice if [1, 2, 3].include?(choice)
      puts "❌ Invalid option!".red
      sleep 1
    end
  end

  def select_word
    filtered = @dictionary.select do |word|
      case @difficulty
      when 1 then word.length <= 5
      when 2 then word.length > 5 && word.length <= 10
      when 3 then word.length > 10
      end
    end
    filtered.empty? ? @dictionary.sample : filtered.sample
  end

  def render_game
    clear_screen
    puts "=== HANGMAN GAME ===".blue.bold
    puts "Player: #{@player_name} | Score: #{@current_score}".cyan
    puts HANGMAN_ART[@wrong_attempts]
    puts "\nWord:       #{@correct_letters.join(' ')}".green.bold
    puts "Used letters: #{@used_letters.join(', ')}".yellow
    puts "Remaining lives: #{6 - @wrong_attempts}"
    puts "Type '1' for a HINT (-#{HINT_PENALTY} pts + 1 error)".magenta
    puts "---------------------".blue
  end

  def ask_for_guess
    print "Type a letter: "
    gets.chomp.upcase
  end

  def valid_guess?(guess)
    return true if guess == "1"
    if guess.length != 1 || !guess.match?(/[A-Z]/)
      puts "❌ Error: Type only ONE letter (A-Z).".red.bold
      sleep 1
      return false
    end
    if @used_letters.include?(guess)
      puts "⚠️ You already tried the letter #{guess}!".yellow
      sleep 1
      return false
    end
    true
  end

  def process_guess(input)
    if input == "1"
      if @wrong_attempts < 5
        @current_score -= HINT_PENALTY
        reveal_hint
      else
        puts "⚠️ Not enough lives to ask for a hint!".yellow.bold
        sleep 1.5
      end
    else
      @used_letters << input
      if @secret_word.include?(input)
        points = (POINTS_PER_LETTER * difficulty_multiplier).to_i
        @current_score += points
        puts "✅ Correct letter! +#{points} points.".green
        @secret_word.each_char.with_index { |char, i| @correct_letters[i] = input if char == input }
        sleep 0.5
      else
        puts "❌ Incorrect letter!".red
        @wrong_attempts += 1
        sleep 1
      end
    end
  end

  def reveal_hint
    missing_indices = @correct_letters.each_index.select { |i| @correct_letters[i] == "_" }
    return if missing_indices.empty?

    random_index = missing_indices.sample
    letter_to_reveal = @secret_word[random_index]
    @wrong_attempts += 1
    
    @secret_word.each_char.with_index do |char, index|
      @correct_letters[index] = char if char == letter_to_reveal
    end
    puts "\n💡 HINT: The letter '#{letter_to_reveal}' has been revealed!".magenta.bold
    sleep 1.5
  end

  def active?
    @wrong_attempts < 6 && @correct_letters.include?("_")
  end

  def save_ranking
    filename = "ranking.json"
    new_entry = {
      name: @player_name,
      score: @current_score,
      errors: @wrong_attempts,
      difficulty: case @difficulty
                  when 1 then "Easy"
                  when 2 then "Medium"
                  when 3 then "Hard"
                  end
    }

    file_data = File.exist?(filename) && !File.zero?(filename) ? JSON.parse(File.read(filename)) : []
    file_data << new_entry
    File.write(filename, JSON.pretty_generate(file_data))
    puts "🏆 Your score has been saved!".green
    sleep 1
  end

  def finalize_game
    render_game
    if !@correct_letters.include?("_")
      victory_bonus = (POINTS_FOR_WIN * difficulty_multiplier).to_i
      @current_score += victory_bonus
      puts "\n🎉 Congratulations, #{@player_name}! You guessed the word: #{@secret_word}".green.bold
      puts "Final Score: #{@current_score} (+#{victory_bonus} victory bonus)".yellow.bold
      save_ranking
    else
      puts "\n💀 Game Over! The secret word was: #{@secret_word}".red.bold
      puts "Final Score: #{@current_score}".yellow.bold
    end
  end
end

# --- Execução da Sessão ---
clear_screen = lambda { Gem.win_platform? ? system("cls") : system("clear") }
clear_screen.call
puts "Welcome to Hangman Ultimate!".cyan.bold
print "Enter your name: "
player_name = gets.chomp.strip
player_name = "Anonymous" if player_name.empty?

session_score = 0
loop do
  game = Hangman.new(player_name, session_score)
  game.play
  session_score = game.current_score 

  print "\nDo you want to play another round? (Y/N): "
  break unless gets.chomp.upcase == 'Y'
end

puts "\nThanks for playing, #{player_name}! Final Score: #{session_score}".green.bold