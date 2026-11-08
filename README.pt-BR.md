# HD Tactical HUD

Uma HUD minimalista, no estilo de jogos de tiro táticos, para o **Hideous Destructor**, junto com o **Centered Magnified Scopes**, num `.pk3` só.

[English](README.md)

> **Status: 1.1.0.** Novo painel de munição no estilo de jogos táticos no canto inferior direito. Veja o [Roadmap](#roadmap) e o [changelog](CHANGELOG.md).

## Requisitos

- [UZDoom](https://github.com/UZDoom/UZDoom) (feito e testado no UZDoom 5.x).
- [Hideous Destructor](https://codeberg.org/mc776/hideousdestructor) **5.0.1a**.

## Instalação

1. Baixe o `HDTacticalHUD-v1.1.0.pk3` em [Releases](../../releases).
2. Carregue **depois** do Hideous Destructor:

   ```
   uzdoom -file hd-5.0.1a.pk7 HDTacticalHUD-v1.1.0.pk3
   ```

3. Configure a tecla de **inspecionar munição**: *Opções → Tactical HUD → Tecla inspecionar munição*. Ela vem sem tecla.

> **Não carregue `BossScopeCentralizado.pk3` nem `BossScopeCentralizado-ModernHUD.pk3` junto com este mod.** O addon de scope já vem incluído, e carregar duas vezes faz o jogo dar erro ao abrir (as mesmas classes seriam definidas duas vezes).

## O que tem

### Vida (canto inferior esquerdo)
- **Paperdoll** do Doomguy, preenchido de branco conforme a vida e esvaziando de cima pra baixo: branco → amarelo → laranja → vermelho, pulsando quando crítico.
- **Vida máxima perdida** (ferimentos, perda de sangue, queimadura…) cresce de cima pra baixo em vermelho escuro com listras diagonais.
- Piscada vermelha ao levar um golpe forte.
- **Armadura** no boneco, como **contorno** colorido (1 a 3 px) ou **colete** no tronco. Verde = garrison, azul = de combate. Esvazia com a durabilidade.
- **ECG** ao lado do boneco, com os batimentos reais do HD e o BPM (dourado/vermelho quando perigoso).

### Munição (canto inferior direito)
Um painel no estilo de jogos táticos, que aparece quando importa e some sozinho:
- **Pentes**: até 3 pentes (o da arma à direita, com uma barra em cima = bala na câmara), "+" e o total quando há mais de 3. Pente vazio = contorno pontilhado piscando vermelho/branco; arma sem pente = piscando branco; pente "sujo" do ZM66 = listras vermelhas. Pentes reservas vazios ficam escondidos, a não ser que você ligue a opção.
- **Cartuchos / balas**: "reserva | laterais + na arma" na Hunter e na double barrel, "reserva | na arma" no Boss rifle e no revólver. Barra em cima do número: bala boa / qualquer coisa na câmara (Hunter, Boss), uma metade por cano (double barrel). 0 vermelho quando vazia.
- **Modo lança-granadas**: granada carregada + reservas. **Granadas de mão**: contagem.
- **Coluna do modo de tiro** só com os modos da arma.
- **Lista de armas** (silhuetas) em cima, ao trocar de arma; granadas numa entrada só, com a contagem.
- Aparece ao trocar de arma, na tecla de inspecionar (segure para manter), ao recarregar/descarregar (só se a arma realmente começar), no pump, ao trocar o modo de tiro (só a coluna do modo). Arma vazia ou travada: aparece no próximo clique de tiro e a munição fica até recarregar ou trocar de arma. Correr/pular/escalar não conta como troca de arma.
- **Movimento de checagem** opcional na tecla de inspecionar (a arma abaixa um pouco e sobe). Só visual.

Vulcanette, BFG, Thunder Buster, motosserra, Brontornis, lança-foguetes, Blooper e armas de outros addons continuam, por enquanto, com o **HUD de munição do HD**, acima do BPM.

### Inventário e itens
- Seletor de itens no **canto superior direito** (desligado / ligado / só ao trocar).
- Chaves e itens vestidos (bolsa de sangue, radsuit…) no **canto superior direito**.

### Bússola (topo, centro)
- **Minimalista** (letras deslizando) ou **barra com marcas**.
- Sempre, ou só segurando Use.
- **Inércia**: desligada / leve / suave / pesada, como uma bússola com líquido.
- **Distância entre os pontos**: curta / média / longa.

### Outros
- **Safe zone**: manter a HUD dentro de 16:9 / 16:10 / 4:3 / 21:9, mais margens laterais e superior/inferior.
- Inglês e português (pt / pt-BR / pt-PT).
- Tudo em *Opções → Tactical HUD* (opções principais + *Opções avançadas*, com *Restaurar padrões*).

### Centered Magnified Scopes (incluído)
Antigo *Boss Scope Centralizado*. Desenha os scopes com zoom do HD no centro da tela, com:
tamanho do scope, tela fora do scope (normal / preta / borrada), zoom fora do scope, sensibilidade normalizada no scope e um botão para desligar o addon inteiro.
Opções: *Tactical HUD → Centered Magnified Scopes*. O borrão precisa de OpenGL ou Vulkan.

## Roadmap

**Ainda falta**
- Painel de munição para: **Vulcanette**, **BFG**, **Thunder Buster**, **motosserra**, **Brontornis**, **lança-foguetes**, **Blooper** e armas de outros addons (hoje usam o HUD do HD).
- Informações que sumiram junto com o HUD do HD nas armas suportadas: **zoom / ajuste de queda da luneta do Boss**, **distância do airburst da granada**.
- A bússola não está ligada ao FOV (as letras não batem exatamente com o mundo).

**Limitações conhecidas**
- O movimento de checagem é um abaixar/levantar genérico, não a animação própria de cada arma.
- Até agora só uma pessoa testou no jogo; reporte problemas em [Issues](../../issues).

## Como gerar o .pk3

O `.pk3` é só um zip dos arquivos do repositório:

```
./build.sh          # gera HDTacticalHUD-v<versão>.pk3
```

## Créditos

- **Hideous Destructor**, de Matt (mc776) e colaboradores.
- Paperdoll baseado no sprite do Doomguy de *Doom* (id Software).
- Inspirado em jogos de tiro táticos como *Ready or Not*, *Insurgency: Sandstorm* e *Escape from Tarkov*.
