# Gestor de Turmas

Central de controle para o representante administrar as 6 turmas da semana (segunda a sábado), com grupos dinâmicos, alunos, líderes, notas individuais e de grupo, diário e relatórios em PDF.

Esta entrega contém três arquivos:
- **`index.html`** — o sistema em si (abra para usar)
- **`schema.sql`** — script para criar o banco de dados real no Supabase (opcional, veja seção 4)
- **`README.md`** — este arquivo

## 1. Como instalar

Não há instalação obrigatória. `index.html` é um único arquivo autocontido que carrega React, Chart.js, jsPDF e (se você conectar um banco) o SDK do Supabase de CDNs públicas no momento em que é aberto no navegador. Basta ter o arquivo salvo em qualquer pasta do computador, ou hospedado em qualquer lugar (veja seção 4 para persistência ao hospedar).

## 2. Como executar

Dê duplo clique em `index.html` (ou abra com "Abrir com... Google Chrome/Edge/Firefox"). É necessário estar conectado à internet apenas para carregar as bibliotecas na primeira vez que a página é aberta (elas ficam em cache do navegador nas vezes seguintes). Nenhum dado seu é enviado para fora do seu computador — tudo roda localmente.

Se preferir servir por um servidor local (opcional, útil para evitar particularidades de `file://` em alguns navegadores):
```
npx serve .
```
e acesse o endereço indicado (ex.: http://localhost:3000).

## 3. Como gerar build

Não há etapa de build. O arquivo já é o produto final — é por isso que a entrega não depende de `npm install`, Vite, TypeScript compilado etc. Isso foi uma escolha deliberada para garantir que o sistema abra e funcione imediatamente em qualquer computador, sem exigir Node.js instalado. Veja a seção 6 para o caminho de evolução para uma stack com build (Vite + TS + Tailwind + shadcn/ui), caso deseje seguir esse caminho depois.

## 4. Onde ficam os dados

Por padrão, tudo é salvo no **localStorage** do navegador, sob a chave `gestor_turmas_v1`. Isso é rápido e funciona offline, mas tem uma limitação importante: **os dados ficam presos àquele navegador/computador específico**. Se você hospedar o `index.html` e acessar de outro dispositivo, ele não vê o que foi salvo no primeiro.

### Modo com banco SQL real (recomendado se for hospedar ou acessar de mais de um aparelho)

O sistema agora também sincroniza com um **banco de dados SQL real (Postgres via Supabase)**, de graça, sem precisar mexer em código — tudo pela própria interface:

1. Crie uma conta gratuita em **[supabase.com](https://supabase.com)** e um novo projeto (leva ~2 minutos para provisionar).
2. No projeto, abra **SQL Editor** (menu lateral) → cole todo o conteúdo do arquivo **`schema.sql`** (incluído nesta entrega) → clique em **Run**. Isso cria todas as tabelas, já com as 6 turmas e as categorias padrão do diário.
3. Vá em **Project Settings → API** e copie dois valores: a **Project URL** e a chave **`anon` `public`**.
4. No Gestor de Turmas, clique no ícone de **banco de dados** na barra lateral (ou em **Relatórios → Conectar banco de dados**), cole a URL e a chave, e clique em **Conectar**.

A partir daí, toda alteração (cadastrar aluno, trocar grupo, lançar nota, registrar diário...) é salva automaticamente no banco SQL. Qualquer navegador/dispositivo que você conectar com a **mesma URL e a mesma chave** vai ler e escrever nos mesmos dados — é assim que você consegue hospedar o sistema (ex.: Vercel, Netlify, GitHub Pages) e ter tudo salvando de verdade, de qualquer lugar.

**Importante sobre segurança:** como não há tela de login (por desenho, pensado para uso de uma única pessoa), o `schema.sql` libera leitura/escrita para a chave `anon` sem exigir autenticação. Isso é adequado para seu uso pessoal, mas significa que qualquer pessoa que descobrisse sua URL + chave também conseguiria alterar os dados. Não publique essas credenciais em lugares públicos (ex.: repositório GitHub público). Se quiser, no futuro, adicionar login, o `schema.sql` já deixa indicado onde trocar as políticas de acesso.

**Se o banco cair, estiver mal configurado ou você estiver offline**, o sistema avisa (ícone fica vermelho) e continua funcionando normalmente salvando no localStorage daquele navegador — nada trava.

### Detalhes técnicos de onde cada coisa fica

- Modo local: chave `gestor_turmas_v1` no localStorage, como um único objeto JSON.
- Credenciais do banco (se conectado): chave `gestor_turmas_sb_config` no localStorage (fica só no seu navegador; não é enviada a lugar nenhum além do próprio Supabase).
- Backup manual do modo local: abra o Console do navegador (F12) e rode `copy(localStorage.getItem('gestor_turmas_v1'))`.
- Backup do modo SQL: os dados já estão no seu projeto Supabase — você pode exportá-los a qualquer momento pelo "Table Editor" ou "SQL Editor" do próprio Supabase.
- Toda a lógica de leitura/escrita está isolada na seção comentada `CAMADA DE ARMAZENAMENTO` e `SINCRONIZAÇÃO COM BANCO SQL`, no topo do arquivo. Nenhum componente de tela acessa `localStorage` ou o Supabase diretamente — todos passam pelas ações (`actions.*`) do componente `App`, que atualizam o estado local e, quando conectado, também gravam no banco.

## 5. Dados de exemplo (opcional — nada é carregado sozinho)

O sistema **abre zerado**: as 6 turmas (segunda a sábado) e as categorias padrão do diário já existem, mas sem nenhum grupo, aluno, nota ou registro fictício. Você cadastra sua turma real direto pela interface, como explicado na pergunta anterior (Ações rápidas → Novo aluno / Novo grupo, ou dentro de cada turma).

Se quiser apenas **testar** o sistema antes de usar pra valer, existe um gerador de dados de exemplo opcional em **Relatórios → Zona de dados → "Carregar dados de exemplo (opcional, para teste)"**. Ele substitui tudo por alunos, grupos e notas fictícios — e mostra um aviso "DADOS DEMONSTRATIVOS" enquanto estiverem ativos. Depois, use **"Limpar tudo e começar do zero"** para voltar ao estado vazio.

Esse gerador fica na função `seedDatabase()` no código, caso queira customizá-lo (nomes, quantidade de grupos por dia etc.) — mas ele só roda se você clicar no botão, nunca sozinho.

## 6. Banco de dados — já conectável, e caminho para evoluir mais

O passo "conectar um banco de dados" já está pronto e é feito pela própria interface (seção 4 acima: crie um projeto Supabase, rode `schema.sql`, cole a URL e a chave no app). Para quem quiser ir além disso no futuro:

- **Escritas mais granulares / regras de negócio no banco**: hoje cada ação do app (`addStudent`, `transferStudent`, `setLeader` etc., dentro de `App`) já faz sua própria chamada de escrita no Supabase (inserts/upserts pontuais, não um dump do JSON inteiro) — então dá para evoluir regra por regra (ex.: trocar um `upsert` por uma `stored procedure` no Postgres) sem reescrever a interface.
- **Entidades**, já mapeadas 1:1 entre o app (camelCase) e as tabelas SQL (snake_case) em `schema.sql`:

```
classes            → id, name, day_index
groups             → id, class_id, name, status(ativo/arquivado), leader_id, group_grade, created_at
students           → id, name, rgm, class_id, group_id, status, observations, created_at
individual_grades  → id, student_id, class_id, group_id, value, label, date
group_grades_history → id, group_id, value, date
diary_entries       → id, date, class_id, group_id, student_id(opcional), category, description, created_at_ms
group_history       → id, group_id, class_id, date, description
student_history     → id, student_id, date, from_group_id, to_group_id, description
categories          → name (chave primária)
app_meta            → id='singleton', is_demo (flag do banner de dados demonstrativos)
```

- **Login/autenticação**: a ausência proposital de tela de login nesta versão não impede adicionar depois — o Supabase já traz Auth pronto. Quando precisar, adicione login por e-mail/senha ou magic link, troque as políticas de RLS em `schema.sql` (hoje liberadas para a chave `anon`) por regras baseadas em `auth.uid()`, e envolva o `Router` com um guard de autenticação.
- **Evoluir para uma stack com build** (React + TypeScript + Vite + Tailwind + shadcn/ui + Recharts + Framer Motion + React Hook Form + Zod, como sugerido originalmente): crie o projeto com `npm create vite@latest gestor-turmas -- --template react-ts` e porte cada componente deste arquivo (já são funções isoladas, sem dependências cruzadas complicadas) para `.tsx` dentro de `src/components`, `src/screens` e `src/services`, tipando as entidades acima como `interface`s TypeScript. A lógica de `actions` e de sincronização com o Supabase pode ser copiada quase sem alterações — o SDK `@supabase/supabase-js` é o mesmo em ambos os cenários.

## O que está implementado

- **Sem login** — abre direto no Dashboard.
- **6 turmas fixas** (segunda a sábado), cada uma com **quantidade independente e editável de grupos** (criar, renomear, arquivar/excluir com proteção quando há alunos/histórico).
- **Alunos** com nome, RGM (com validação de duplicidade), grupo atual, observações, histórico de grupos e histórico de notas.
- **Reorganização de grupos** por formulário e por **arrastar e soltar** (quadro Kanban dentro da aba "Grupos" de cada turma).
- **Líder de grupo** destacado com 🏆, alterável, com registro automático no histórico do grupo.
- **Notas individuais** e **notas de grupo**, tratadas como entidades separadas.
- **Diário da turma**, com data, turma, grupo (opcional) e aluno (opcional) — o contexto de grupo é gravado no momento do registro e nunca é reescrito se o aluno mudar de grupo depois, preservando o histórico corretamente. Categorias podem ser criadas livremente.
- **Dashboard** com totais gerais, cards por dia (calculados dinamicamente), gráfico de alunos por dia, líderes atuais, ocorrências recentes e últimas alterações.
- **Página da turma** com abas: Visão geral, Alunos, Grupos, Notas, Diário, Histórico.
- **Perfil do grupo** com integrantes, notas, diário, histórico de entrada/saída de alunos e alterações do grupo (líder, nome, nota).
- **Perfil do aluno** com evolução de notas em gráfico, histórico de grupos em linha do tempo e registros de diário.
- **Busca global** por nome, RGM ou nome de grupo.
- **Ações rápidas** no topo: novo aluno, novo grupo, lançar nota, registrar diário, gerar relatório.
- **Central de relatórios** com filtros (turma, grupo, aluno, categoria, data inicial/final) e **geração real de PDF** (jsPDF + autoTable) com resumo, tabela de alunos/notas e tabela de diário.
- **Persistência real**: localStorage por padrão, com sincronização opcional a um **banco SQL (Postgres/Supabase)** configurável pela própria interface — veja seção 4 — para funcionar hospedado e em múltiplos dispositivos.
- **Começa zerado** (sem alunos, grupos ou notas fictícios) — com um gerador de dados de exemplo totalmente opcional, só para teste, que nunca carrega sozinho.
- Responsivo (sidebar colapsável em telas estreitas), com animações discretas de entrada, hover e modais, e validações de formulário com mensagens claras.

## Fluxo principal

```
Dashboard → escolher dia → grupos → alunos → transferir/editar → lançar nota
→ registrar diário → (grupo/aluno) histórico → Relatórios → Gerar PDF
```

Qualquer alteração de estrutura — adicionar/remover grupo, mudar quantidade de grupos por dia, transferir aluno, trocar líder — é feita inteiramente pela interface, sem precisar mexer em código.
