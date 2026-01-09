# --- Jogo da Forca: Versão Visual (ASCII) ---

# 1. O "Banco de Imagens" do nosso jogo
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

def limpar_tela
  Gem.win_platform? ? system("cls") : system("clear")
end

# 2. Novo método para exibir o estado atual
def exibir_jogo(palavra_oculta, erros, tentativas)
  limpar_tela
  puts "=== JOGO DA FORCA ==="
  # O índice do desenho é o número de erros cometidos
  # Se o jogador tem 6 vidas e errou 0, mostramos FORCA_VISUAL[0]
  puts FORCA_VISUAL[erros]
  puts "\nPalavra: #{palavra_oculta.join(' ')}"
  puts "Tentativas: #{tentativas.join(', ')}"
  puts "Vidas restantes: #{6 - erros}"
  puts "---------------------"
end

# --- Lógica Principal (Refatorada) ---

dicionario = ["RUBY", "PROGRAMADOR", "CODIGO", "COMPUTADOR", "VARIAVEL"]
palavra_secreta = dicionario.sample 
letras_certas = Array.new(palavra_secreta.length, "_")
erros_cometidos = 0 # Mudamos a lógica de "vidas" para "erros" para casar com o Array
letras_utilizadas = []

while erros_cometidos < 6 && letras_certas.include?("_")
  exibir_jogo(letras_certas, erros_cometidos, letras_utilizadas)
  
  print "Digite uma letra: "
  chute = gets.chomp.upcase

  if chute.length != 1 || !chute.match?(/[A-Z]/) || letras_utilizadas.include?(chute)
    puts "❌ Entrada inválida ou já utilizada!"
    sleep 1
    next
  end

  letras_utilizadas << chute

  if palavra_secreta.include?(chute)
    palavra_secreta.each_char.with_index do |l, i|
      letras_certas[i] = chute if l == chute
    end
  else
    erros_cometidos += 1 # Aumenta o erro, o que muda o desenho da próxima vez
  end
end

exibir_jogo(letras_certas, erros_cometidos, letras_utilizadas)

if !letras_certas.include?("_")
  puts "🎉 Parabéns! Você venceu!"
else
  puts "💀 Game Over! A palavra era: #{palavra_secreta}"
end