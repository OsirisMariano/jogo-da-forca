# --- Jogo da Forca: Versão Visual (ASCII) ---

# 1. Banco de Imagens
FORCA_VISUAL = [
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

# 2. Métodos de Suporte
def limpar_tela
  Gem.win_platform? ? system("cls") : system("clear")
end

def exibir_jogo(palavra_oculta, erros, tentativas)
  limpar_tela
  puts "=== JOGO DA FORCA ==="
  puts FORCA_VISUAL[erros]
  puts "\nPalavra: #{palavra_oculta.join(' ')}"
  puts "Tentativas: #{tentativas.join(', ')}"
  puts "Vidas restantes: #{6 - erros}"
  puts "---------------------"
end

def carregar_dicionario
  arquivo = "palavras.txt"
  if File.exist?(arquivo)
    palavras = File.read(arquivo).split.map(&:strip).reject(&:empty?)
    if palavras.empty?
      puts "⚠️ O arquivo palavras.txt está vazio. Usando palavra padrão."
      return ["RUBY"]
    end
    palavras
  else
    puts "❌ Erro: O arquivo 'palavras.txt' não foi encontrado!"
    exit
  end
end

def escolher_dificuldade
  loop do
    limpar_tela
    puts "=== ESCOLHA A DIFICULDADE ==="
    puts "1. Fácil (Até 5 letras)"
    puts "2. Médio (6 a 10 letras)"
    puts "3. Difícil (Mais de 10 letras)"
    print "\nOpção: "
    escolha = gets.chomp.to_i
    return escolha if [1, 2, 3].include?(escolha)
    puts "❌ Opção inválida! Escolha 1, 2 ou 3."
    sleep 1
  end
end

def salvar_ranking(nome, erros)
  File.open("ranking.txt", "a") do |arquivo|
    arquivo.puts("#{nome};#{erros}")
  end
end

def exibir_ranking
  limpar_tela
  puts "🏆 --- RANKING DOS MESTRES --- 🏆"
  if !File.exist?("ranking.txt") || File.zero?("ranking.txt")
    puts "O ranking está vazio. Seja o primeiro a vencer!"
  else
    jogadores = File.readlines("ranking.txt").map do |linha|
      nome, erros = linha.strip.split(";")
      { nome: nome, erros: erros.to_i }
    end
    ranking_ordenado = jogadores.sort_by { |j| j[:erros] }.first(5)
    ranking_ordenado.each_with_index do |j, i|
      medalha = case i
                when 0 then "🥇"
                when 1 then "🥈"
                when 2 then "🥉"
                else "  "
                end
      puts "#{medalha} #{i + 1}. #{j[:nome].ljust(12)} | Erros: #{j[:erros]}"
    end
  end
  puts "-------------------------------\n"
  print "Pressione ENTER para começar o desafio..."
  gets
end

# --- Lógica Principal ---
exibir_ranking
dicionario = carregar_dicionario
nivel = escolher_dificuldade

dicionario_filtrado = dicionario.select do |palavra|
  case nivel
  when 1 then palavra.length <= 5
  when 2 then palavra.length > 5 && palavra.length <= 10
  when 3 then palavra.length > 10
  end
end

if dicionario_filtrado.empty?
  puts "⚠️ Nenhuma palavra para esse nível. Usando o dicionário completo."
  dicionario_filtrado = dicionario
end

# Sorteia da lista FILTRADA
palavra_secreta = dicionario_filtrado.sample.upcase

letras_certas = Array.new(palavra_secreta.length, "_")
erros_cometidos = 0 
letras_utilizadas = []

while erros_cometidos < 6 && letras_certas.include?("_")
  exibir_jogo(letras_certas, erros_cometidos, letras_utilizadas)
  print "Digite uma letra: "
  chute = gets.chomp.upcase

  if chute.length != 1 || !chute.match?(/[A-Z]/)
    puts "❌ Erro: Digite apenas UMA letra (A-Z)."
    sleep 1
    next
  end

  if letras_utilizadas.include?(chute)
    puts "⚠️ Você já tentou a letra #{chute}!"
    sleep 1
    next
  end

  letras_utilizadas << chute

  if palavra_secreta.include?(chute)
    palavra_secreta.each_char.with_index do |letra, indice|
      letras_certas[indice] = chute if letra == chute
    end
  else
    puts "❌ Letra incorreta!"
    erros_cometidos += 1
    sleep 1
  end
end

exibir_jogo(letras_certas, erros_cometidos, letras_utilizadas)

if !letras_certas.include?("_")
  puts "🎉 Parabéns! Você venceu!"
  print "Digite seu nome para o ranking: "
  nome = gets.chomp.strip
  nome = "Anônimo" if nome.empty?
  salvar_ranking(nome, erros_cometidos)
  puts "✅ Resultado salvo!"
  sleep 1
else
  puts "💀 Game Over! A palavra era: #{palavra_secreta}"
end