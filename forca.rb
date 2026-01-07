def limpar_tela
  if Gem.win_platform?
    system "cls"
  else
    system "clear"
  end
end

dicionario = ["RUBY", "PROGRAMADOR", "CODIGO", "COMPUTADOR", "VARIAVEL"]
palavra_secreta = dicionario.sample 
letras_certas = Array.new(palavra_secreta.length, "_")
tentativas_restantes = 6
letras_utilizadas = []


while tentativas_restantes > 0 && letras_certas.include?("_")
  limpar_tela
  puts "--- JOGO DA FORCA ---"
  puts "Dica: A palavra tem #{palavra_secreta.length} letras."
  puts "\nPalavra: #{letras_certas.join(" ")}"
  
  print "Digite uma letra: "
  chute = gets.chomp.upcase

  if chute.length != 1 || !chute.match?(/[A-Z]/)
    puts "Erro: Digite apenas UMA letra(A-Z)."
    next
  end

  if letras_utilizadas.include?(chute)
    puts "Você já tentou a letra #{chute}!"
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

if !letras_certas.include?("_")
  puts "\n🎉 Parabéns! Você venceu. A palavra era #{palavra_secreta}."
else
  puts "\n💀 Fim de jogo. A palavra era #{palavra_secreta}."
end