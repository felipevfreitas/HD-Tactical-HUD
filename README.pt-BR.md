# HD Tactical HUD

Uma HUD minimalista, no estilo de jogos de tiro táticos, para o **Hideous Destructor**, junto com o **Centered Magnified Scopes**, num `.pk3` só.

[English](README.md)

> **Status: 1.1.0, em desenvolvimento.** A parte de munição está sendo **refeita** (novo painel no estilo de jogos táticos no canto inferior direito). Veja o [Roadmap](#roadmap) e o [changelog](CHANGELOG.md).

## Requisitos

- [UZDoom](https://github.com/UZDoom/UZDoom) (feito e testado no UZDoom 5.x).
- [Hideous Destructor](https://codeberg.org/mc776/hideousdestructor) **5.0.1a**.

## Instalação

1. Baixe o `HD-Tactical-HUD-v1.1.0.pk3` em [Releases](../../releases).
2. Carregue **depois** do Hideous Destructor:

   ```
   uzdoom -file hd-5.0.1a.pk7 HD-Tactical-HUD-v1.1.0.pk3
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

### Munição
- **Tecla de inspecionar** (segure para manter na tela): mostra embaixo, no centro, o que está **na arma** e depois a **munição reserva**. Cada pente/bateria é uma silhueta que esvazia de cima pra baixo.
- Também pode abrir ao **recarregar / recarga secundária / descarregar**, só se a arma realmente começar a fazer isso.
- Opção **"sempre mostrar a munição da arma"** (a reserva continua aparecendo só na checagem).
- **Movimento de checagem**: a arma abaixa um pouco e sobe (velocidade e profundidade ajustáveis). É só visual, nunca muda o estado da arma.
- Modo de tiro (SEMI / RAJADA / AUTO / GRANADA, RPM da Vulcanette, modo da Thunder Buster).
- A cor da munição pode seguir a cor do jogador (o verde do HD).

Armas com desenho próprio (o HUD de munição do HD fica escondido nelas):

| Arma | O que aparece |
|---|---|
| Pistola, SMG, ZM66, Liberator | Pente da arma + bala da câmara (+ lança-granadas). A ZM66 sempre mostra o contador vermelho; pente recarregado ("sujo") fica com listras vermelhas pulsando e número aleatório. |
| Vulcanette | Pente alimentando (com contador), bateria pequena em cima das 4 caixinhas da fila, bala que esvazia com as 5 câmaras. |
| BFG 9000 | As duas baterias (+ "ARNÊS"); aparece sozinha enquanto carrega. |
| Thunder Buster, motosserra | Bateria. |
| Hunter | Um cartucho: plástico = tubo, metal = cano (branco = novo, escuro = gasto, transparente = vazio), listras vermelhas quando trava; cartuchos da lateral. Olhada rápida a cada pump. |

As outras armas continuam com o **HUD de munição original do HD**, acima do BPM.

### Inventário e itens
- Seletor de itens no **canto inferior direito** (desligado / ligado / só ao trocar).
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

**Planejado**
- **Refazer a HUD de munição.** O painel de checagem atual funciona, mas não gostei do visual; ele vai ser redesenhado.

**Ainda falta**
- Desenho próprio para: **Slayer**, **revólver**, **Boss rifle**, **Brontornis**, **lança-foguetes**, **Blooper** e armas de outros addons (hoje usam o HUD do HD).
- Informações que sumiram junto com o HUD do HD nas armas suportadas: **nível de zoom da luneta**, **distância do airburst da granada**, **telêmetro da Thunder Buster**, **medidor de dano na parede da motosserra**.
- A bússola não está ligada ao FOV (as letras não batem exatamente com o mundo).

**Limitações conhecidas**
- O movimento de checagem é um abaixar/levantar genérico, não a animação própria de cada arma.
- Até agora só uma pessoa testou no jogo; reporte problemas em [Issues](../../issues).

## Como gerar o .pk3

O `.pk3` é só um zip dos arquivos do repositório:

```
./build.sh          # gera HD-Tactical-HUD-v<versão>.pk3
```

## Créditos

- **Hideous Destructor**, de Matt (mc776) e colaboradores.
- Paperdoll baseado no sprite do Doomguy de *Doom* (id Software).
- Inspirado em jogos de tiro táticos como *Ready or Not*, *Insurgency: Sandstorm* e *Escape from Tarkov*.
