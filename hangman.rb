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

def clear_screen
  Gem.win_platform? ? system("cls") : system("clear")
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

  # Larguras das colunas
  COL_RANK = 6
  COL_NAME = 15
  COL_SCORE = 8
  COL_ERRS = 8

  # Regras de Pontuação
  POINTS_PER_LETTER = 20
  POINTS_FOR_WIN    = 100
  HINT_PENALTY      = 50

  attr_reader :current_score
  def initialize(player_name , initial_score)
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

  def reveal_hint
    # 1. Encontra os índices das letras que ainda são "_"
    missing_indices = @correct_letters.each_index.select { |i| @correct_letters[i] == "_" }

    # 2. Se por algum motivo não houver mais letras (segurança), encerra
    return if missing_indices.empty?

    # 3. Sorteia um desses índices e descobre qual letra mora lá na palavra secreta
    random_index = missing_indices.sample
    letter_to_reveal = @secret_word[random_index]

    # 4. "Custo" da dica: aumenta as tentativas erradas
    @wrong_attempts += 1
    
    # 5. Revela a letra em todas as posições onde ela aparece
    @secret_word.each_char.with_index do |char, index|
      @correct_letters[index] = char if char == letter_to_reveal
    end

    puts "\n💡 HINT: The letter '#{letter_to_reveal}' has been revealed!".cyan.bold
    sleep 1.5
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

    mult_text = "x#{difficlty_multiplier}"
    puts "Score: #{@current_score}".yellow.bold + "(#{mult_text})".cyan

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
        name, score, errors, diff = line.strip.split(";")
        { name: name, score: score.to_i, errors: errors.to_i, difficulty: diff }
      end

      # 2. FILTRAMOS apenas pela dificuldade desejada
      filtered_players = players.select { |p| p[:difficulty].strip == filter_difficulty }

      if filtered_players.empty?
        puts "No records yet for #{filter_difficulty} difficulty.".yellow
      else
        top_players = filtered_players.sort_by { |p| -p[:score] }.first(5)

        puts draw_line.blue
        puts "| #{"RANK".center(COL_RANK)} | #{"PLAYER".center(COL_NAME)} | #{"SCORE".center(COL_SCORE)} | #{"ERRORS".center(COL_ERRS)} |".blue.bold

        top_players.each_with_index do |p, i|
          medal = case i
                  when 0 then "🥇"
                  when 1 then "🥈"
                  when 2 then "🥉"
                  else " #{i + 1} "
                  end
          
          # Alinhando os dados
          rank_cell  = medal.center(COL_RANK - 1)
          name_cell  = p[:name].to_s.ljust(COL_NAME)
          score_cell = p[:score].to_s.center(COL_SCORE)
          errs_cell  = p[:errors].to_s.center(COL_ERRS)

          puts "| #{rank_cell} | #{name_cell} | #{score_cell} | #{errs_cell} |".yellow
        end

        puts draw_line.blue
      end
    end
    #puts "-------------------------------\n".cyan
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
    return true if guess == "1"

    if guess.length != 1 || !guess.match?(/[A-Z]/)
      puts "❌ Error: Type only ONE letter (A-Z) or '1' for hint.".red.bold
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
      letter = input
      @used_letters << letter

      if @secret_word.include?(letter)
        point = (POINTS_PER_LETTER * difficulty_multiplier).to_i
        @current_score += point
        puts "✅ Correct letter! You earned #{point} points.".green
        @secret_word.each_char.with_index do |char, index|
          @correct_letters[index] = letter if char == letter
        end
        sleep 0.5
      else
        puts "❌ Incorrect letter!".red
        @wrong_attempts += 1
        sleep 1
      end
    end
  end

  # --- Finalization Methods ---
  def render_game
    clear_screen
    puts "=== HANGMAN GAME ===".blue.bold
    puts HANGMAN_ART[@wrong_attempts]
    puts "\nWord:       #{@correct_letters.join(' ')}".green.bold
    puts "Attempts:    #{@used_letters.join(', ')}".yellow
    puts "Remaining:   #{6 - @wrong_attempts}"
    puts "---------------------".blue
  end

  def save_ranking
    difficulty_name = case @difficulty
                      when 1 then "Easy"
                      when 2 then "Medium"
                      when 3 then "Hard"
                      end
    
    File.open("ranking.txt", "a") do |file|
      file.puts("#{@player_name};#{@current_score};#{@wrong_attempts};#{difficulty_name}")
    end
    puts "✅ Result saved in #{@play_name}" .green
    sleep 1
  end

  def finalize_game
    render_game
    if !@correct_letters.include?("_")
      victory_points = (POINTS_FOR_WIN * difficulty_multiplier).to_i
      @current_score += victory_points

      puts "\n🎉 Congratulations, #{@player_name}! You guessed the word: #{@secret_word}".green.bold
      puts "Final Score: #{@current_score}".yellow.bold
      save_ranking
    else
      puts "\n💀 Game Over! The secret word was: #{@secret_word}".red.bold
      puts "Final Score: #{@current_score}".yellow.bold
    end
  end
end

# --- Session Execution ---
clear_screen
puts "Welcome to Hangman Ultimate!".cyan.bold
print "Enter your name to start the session: "
player_name = gets.chomp.strip
player_name = "Anonymous" if player_name.empty?

session_score = 0
play_again = true

while play_again
  game = Hangman.new(player_name, session_score)
  game.play
  
  # Após o jogo acabar, pegamos o score atualizado
  session_score = game.current_score 

  print "\nDo you want to play another round? (Y/N): "
  choice = gets.chomp.upcase
  play_again = (choice == 'Y')
end

puts "\nThanks for playing, #{player_name}! Your final score was: #{session_score}".green.bold