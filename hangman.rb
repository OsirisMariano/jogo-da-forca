require 'colorize'

# Fallback for colors if gem is missing
begin
  require 'colorize'
rescue LoadError
  class String
    def red; self; end; def green; self; end; def yellow; self; end
    def blue; self; end; def cyan; self; end; def bold; self; end
  end
end

# --- Constants ---
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
  def initialize
    ranking_menu
    @category = choose_category
    @dictionary = load_dictionary
    @difficulty = choose_difficulty
    @secret_word = select_word.upcase
    @correct_letters = Array.new(@secret_word.length, "_")
    @wrong_attempts = 0
    @used_letters = []
  end

  # --- Public Method: The entry point ---
  def play
    while active?
      render_game
      guess = ask_for_guess
      process_guess(guess) if valid_guess?(guess)
    end

    finalize_game
  end

  private

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
      choise = gets.chomp.to_i

      case choise
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

  def choose_category
    loop do
      clear_screen
      puts "=== CHOOSE CATEGORY ===".cyan.bold
      puts "1. Animals"
      puts "2. Countries"
      puts "3. Programming"
      print "\nEscolha uma opção: "
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

  # --- Setup Methods ---
  def load_dictionary
    filename = "data/#{@category}.txt"
    if File.exist?(filename)
      words = File.read(filename).split.map(&:strip).reject(&:empty?)
      return words unless words.empty?
      
      puts "⚠️ words.txt is empty. Using default word.".yellow
      ["RUBY"]
    else
      puts "❌ Error: 'palavras.txt' not found!".red
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

  # --- Interface Methods ---
  def clear_screen
    Gem.win_platform? ? system("cls") : system("clear")
  end

  def render_game
    clear_screen
    puts "=== HANGMAN GAME ===".blue.bold
    puts HANGMAN_ART[@wrong_attempts]
    puts "\nWord:        #{@correct_letters.join(' ')}".green.bold
    puts "Attempts:    #{@used_letters.join(', ')}".yellow
    puts "Remaining:   #{6 - @wrong_attempts}"
    puts "---------------------".blue
  end

  def display_ranking(filter_difficulty = "Easy") # Valor padrão é Easy
    clear_screen
    puts "🏆 --- #{filter_difficulty.upcase} RANKING --- 🏆".cyan.bold
    
    if !File.exist?("ranking.txt") || File.zero?("ranking.txt")
      puts "Ranking is empty. Be the first to win!".yellow
    else
      # 1. Lemos todas as linhas
      players = File.readlines("ranking.txt").map do |line|
        name, errors, diff = line.strip.split(";")
        { name: name, errors: errors.to_i, difficulty: diff }
      end

      # 2. FILTRAMOS apenas pela dificuldade desejada
      filtered_players = players.select { |p| p[:difficulty].strip == filter_difficulty }

      if filtered_players.empty?
        puts "No records yet for #{filter_difficulty} difficulty.".yellow
      else
        # 3. Ordenamos os filtrados pelos erros (do menor para o maior)
        top_players = filtered_players.sort_by { |p| p[:errors] }.first(5)

        top_players.each_with_index do |p, i|
          medal = case i
                  when 0 then "🥇"
                  when 1 then "🥈"
                  when 2 then "🥉"
                  else "  "
                  end
          puts "#{medal} #{i + 1}. #{p[:name].to_s.ljust(12)} | Errors: #{p[:errors]}".yellow
        end
      end
    end
    puts "-------------------------------\n".cyan
    print "Press ENTER to continue..."
    gets
  end


  # --- Logic Methods ---
  def active?
    @wrong_attempts < 6 && @correct_letters.include?("_")
  end

  def ask_for_guess
    print "Type a letter: "
    gets.chomp.upcase
  end

  def valid_guess?(guess)
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

  def process_guess(letter)
    @used_letters << letter
    if @secret_word.include?(letter)
      @secret_word.each_char.with_index do |char, index|
        @correct_letters[index] = letter if char == letter
      end
    else
      puts "❌ Incorrect letter!".red
      @wrong_attempts += 1
      sleep 1
    end
  end

  # --- Finalization Methods ---
  def finalize_game
    render_game
    if !@correct_letters.include?("_")
      puts "🎉 Congratulations! You won!".green.bold
      save_ranking
    else
      puts "💀 Game Over! The word was: #{@secret_word}".red.bold
    end
  end

  def save_ranking
    print "Enter your name for the ranking: "
    name = gets.chomp.strip
    name = "Anonymous" if name.empty?

    difficulty_name = case @difficulty
                      when 1 then "Easy"
                      when 2 then "Medium"
                      when 3 then "Hard"
                      end
    
    File.open("ranking.txt", "a") do |file|
      file.puts("#{name};#{@wrong_attempts};#{difficulty_name}")
    end
    puts "✅ Result saved in #{difficulty_name} mode!".green
    sleep 1
  end
end

# --- Execution ---
game = Hangman.new
game.play