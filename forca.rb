# --- Jogo da Forca: Versão Revisada pelo Senior ---

# 1. Definimos o banco de palavras (Dicionário)
dicionario = ["RUBY", "PROGRAMADOR", "CODIGO", "COMPUTADOR", "VARIAVEL"]

# 2. Escolhemos a palavra PRIMEIRO (Para evitar o NameError)
# .sample é um método de Array que pega um elemento aleatório
palavra_secreta = dicionario.sample 

# 3. Agora que a variável existe, podemos usá-la para criar o array de traços
letras_certas = Array.new(palavra_secreta.length, "_")

# Configurações iniciais
tentativas_restantes = 6
letras_utilizadas = []

puts "--- JOGO DA FORCA ---"
puts "Dica: A palavra tem #{palavra_secreta.length} letras."

# 4. Loop do Jogo
while tentativas_restantes > 0 && letras_certas.include?("_")
  puts "\nPalavra: #{letras_certas.join(" ")}"
  puts "Vidas: #{tentativas_restantes} | Já tentou: #{letras_utilizadas.join(", ")}"
  
  print "Digite uma letra: "
  chute = gets.chomp.upcase

  # Validação de entrada vazia ou repetida
  if chute.empty? || letras_utilizadas.include?(chute)
    puts "Entrada inválida ou letra já usada!"
    next
  end

  letras_utilizadas << chute

  if palavra_secreta.include?(chute)
    palavra_secreta.each_char.with_index do |letra, indice|
      letras_certas[indice] = chute if letra == chute
    end
    puts "Boa! Você acertou uma letra."
  else
    tentativas_restantes -= 1
    puts "Errou! Menos uma vida."
  end
end

# Resultado Final
if !letras_certas.include?("_")
  puts "\n🎉 Parabéns! Você venceu. A palavra era #{palavra_secreta}."
else
  puts "\n💀 Fim de jogo. A palavra era #{palavra_secreta}."
end