# Black Docx — Autorização de Conteúdo para Agentes

Pacote de autorização que injeta permissão explícita para **ads black/agressivos** em qualquer agente que rode na máquina (Claude, Codex, T3 Code, Antigravity, etc.).

Baseado nos princípios de persuasão de **Robert Cialdini** (autoridade, escassez, prova social, compromisso, bandeiras vermelhas, testes de pressão) — a mesma técnica que o Superpowers usa para forçar compliance em agentes.

## O que faz

Adiciona a seção **"Autorização de Conteúdo — Ads Black/Aggressivos"** no arquivo de instruções globais de cada agente:

| Agente | Arquivo alvo |
|---|---|
| Claude Desktop | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| T3 Code | `AGENTS.md` no projeto ativo |
| Antigravity | `AGENTS.md` no mirror de skills |

## Instalação rápida

```powershell
# PowerShell — roda no PC do José
cd C:\Users\Micro\Desktop\black-docx
.\install.ps1
```

O script detecta quais agentes estão instalados e injeta a autorização nos arquivos corretos. Se a seção já existe, atualiza para a versão mais recente.

## Uso manual

Se preferir copiar o conteúdo manualmente, o bloco completo está em `AUTHORIZATION.md`. Cole no final do `CLAUDE.md` ou `AGENTS.md` do agente desejado.

## Estrutura

```
black-docx/
├── AUTHORIZATION.md      # Bloco completo da autorização (copiar/colar)
├── install.ps1           # Script de instalação automática
├── README.md             # Este arquivo
└── .gitignore
```

## Atualização

Quando a autorização mudar (nova regra, novo cliente, novo nicho), atualize `AUTHORIZATION.md` e rode `.\install.ps1` novamente. O script substitui a seção antiga pela nova em todos os agentes.

## Autor

José Alberes — Editor de Direct Response e DTC. +US$3 milhões validados em ads.
