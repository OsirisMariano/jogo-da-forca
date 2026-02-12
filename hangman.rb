require 'json'

# --- Fallback para cores se a gem colorize não estiver disponível ---
begin
  require 'colorize'
rescue LoadError
  class String
    def red; self; end; def green; self; end; def yellow; self; end
    def blue; self; end; def cyan; self; end; def bold; self; end
    def magenta; self; end; def light_black; self; end
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
  attr_reader :secret_word


  def initialize(player_name, initial_score, excluded_words = [])
    @player_name = player_name
    @current_score = initial_score
    @excluded_words = excluded_words
    @message = ""

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
    
    # 1. Envolvemos a leitura em um bloco de tratamento de erro
    begin
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
    rescue JSON::ParserError
      # 2. Se o arquivo estiver corrompido, avisamos o usuário em vez de quebrar o jogo
      puts "\n⚠️  Error: Ranking data is corrupted and cannot be read.".red
      puts "A backup might be needed or the file will be reset on next save.".red
    rescue StandardError => e
      # 3. Captura qualquer outro erro inesperado (ex: falta de permissão de leitura)
      puts "\n❌ Unexpected error: #{e.message}".red
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
      puts "4. Surprise (All categories)"
      print "\nChoice: "
      choice = gets.chomp.to_i

      case choice
      when 1 then return "animals"
      when 2 then return "countries"
      when 3 then return "programming"
      when 4 then return "surprise"
      else
        puts "❌ Invalid option!".red
        sleep 1
      end
    end
  end

  def load_dictionary
    if @category == "surprise"
      all_words = []
      Dir.glob("data/*.txt").each do |file|
        # O .read.split quebra por QUALQUER espaço em branco (espaço, tab, nova linha)
        words = File.read(file).split(/[\s,]+/).map(&:strip).reject(&:empty?)
        all_words += words
      end
      return all_words.uniq.map(&:upcase)
    end

    filename = "data/#{@category}.txt"
    if File.exist?(filename)
      # Usamos split com Regex para aceitar vírgulas ou espaços como separadores
      words = File.read(filename).split(/[\s,]+/).map(&:strip).reject(&:empty?)
      return words.map(&:upcase) unless words.empty?
      ["RUBY"]
    else
      ["RUBY"]
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
    filtered = @dictionary.select { |w| @excluded_words.include?(w) }.select do |word|
      case @difficulty
      when 1 then word.length <= 5
      when 2 then word.length > 5 && word.length <= 10
      when 3 then word.length > 10
      end
    end
    if filtered.empty? 
      @dictionary.sample
    else
      filtered.sample
    end
  end

  def render_game
    clear_screen
    puts "=== HANGMAN GAME ===".blue.bold
    puts "Player: #{@player_name} | Score: #{@current_score}".cyan
    
    if !@message.empty?
      puts "\n#{@message}".yellow.bold 
      @message = "" 
    end

    hangman_color = case @wrong_attempts
                    when 0..2 then :cyan
                    when 3..4 then :yellow
                    else :red
                    end

    puts HANGMAN_ART[@wrong_attempts].colorize(hangman_color)
    
    puts "\nWord:       #{@correct_letters.join(' ')}"
    puts "Used letters: #{@used_letters.join(', ')}".light_black
    
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
      @message = "❌ Error: Type only ONE letter (A-Z)."
      return false
    end
    if @used_letters.include?(guess)
      @message = "⚠️ You already tried the letter #{guess}!"
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
        @message = "⚠️ Not enough lives to ask for a hint!"
      end
    else
      @used_letters << input
      if @secret_word.include?(input)
        points = (POINTS_PER_LETTER * difficulty_multiplier).to_i
        @current_score += points
        @message = "✅ Correct! +#{points} points."
        @secret_word.each_char.with_index do |char, i|
          @correct_letters[i] = input.green.bold if char == input
        end
      else
        @message = "❌ Incorrect letter!"
        @wrong_attempts += 1
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
      @correct_letters[index] = char.magenta.bold if char == letter_to_reveal
    end
    @message = "💡 HINT! The letter '#{letter_to_reveal}' has been revealed."
  end

  def active?
    @wrong_attempts < 6 && @correct_letters.include?("_")
  end

  def save_ranking
    filename = "ranking.json"

    clean_name = @player_name.gsub(/[^a-zA-Z0-9]/, '').strip[0..12]
    clean_name = "Anonymous" if clean_name.empty?

    new_entry = {
      name: clean_name,
      score: @current_score,
      errors: @wrong_attempts,
      difficulty: case @difficulty
                  when 1 then "Easy"
                  when 2 then "Medium"
                  when 3 then "Hard"
                  end
    }

    begin 
      file_data = []
      if File.exist?(filename) && !File.zero?(filename)
        file_content = File.read(filename)
        file_data = JSON.parse(file_content)
        
      end

      file_data << new_entry
      File.write("#{filename}.bak", JSON.pretty_generate(file_data)) if File.exist?(filename)
    end

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
clear_screen_proc = lambda { Gem.win_platform? ? system("cls") : system("clear") }
clear_screen_proc.call

puts "Welcome to Hangman Ultimate!".cyan.bold
print "Enter your name: "
player_name = gets.chomp.strip
player_name = "Anonymous" if player_name.empty?

session_score = 0
played_history = []

loop do
  game = Hangman.new(player_name, session_score, played_history)
  game.play

  played_history << game.secret_word
  session_score = game.current_score 

  print "\nDo you want to play another round? (Y/N): "
  break unless gets.chomp.upcase == 'Y'
end

puts "\nThanks for playing, #{player_name}! Final Score: #{session_score}".green.bold

session_score = 0
played_history = [] # <--- Novo: Guarda as palavras usadas na sessão

loop do
  game = Hangman.new(played_name, session_score, played_history)
  # Precisamos expor a palavra escolhida para guardar no histórico
  # Adicione attr_reader :secret_word no topo da classe Hangman se não tiver
  
  game.play
  
  played_history << game.secret_word # Salva a palavra que acabou de ser jogada
  session_score = game.current_score 

  print "\nDo you want to play another round? (Y/N): "
  break unless gets.chomp.upcase == 'Y'
end