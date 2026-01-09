# --- Jogo da Forca: Versão Visual (ASCII) ---

# 1. Banco de Imagens (Constante)
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
    # readlines cria um array onde cada linha é um item
    # .map(&:strip) remove o "enter" (\n) invisível no fim de cada palavra
    # .select { |p| !p.empty? } ignora linhas vazias acidentais
    palavras = File.read(arquivo).split.map(&:strip).reject(&:empty?)
    
    if palavras.empty?
      puts "⚠️ O arquivo palavras.txt está vazio. Usando palavra padrão."
      return ["RUBY"]
    end
    
    palavras
  else
    puts "❌ Erro: O arquivo 'palavras.txt' não foi encontrado!"
    puts "Certifique-se de que ele está na mesma pasta que o forca.rb"
    exit # Encerra o programa se não houver palavras
  end
end
# --- Lógica Principal ---

dicionario = carregar_dicionario
palavra_secreta = dicionario.sample.upcase

letras_certas = Array.new(palavra_secreta.length, "_")
erros_cometidos = 0 
letras_utilizadas = []

# Loop principal do jogo
while erros_cometidos < 6 && letras_certas.include?("_")
  exibir_jogo(letras_certas, erros_cometidos, letras_utilizadas)
  
  print "Digite uma letra: "
  chute = gets.chomp.upcase

  # Validação de Entrada
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

  # Verificação do Chute
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

# Finalização do Jogo
exibir_jogo(letras_certas, erros_cometidos, letras_utilizadas)

if !letras_certas.include?("_")
  puts "🎉 Parabéns! Você venceu!"
else
  puts "💀 Game Over! A palavra era: #{palavra_secreta}"
end