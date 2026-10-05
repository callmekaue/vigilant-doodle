-- ============================================================
-- GESTOR DE TURMAS — schema SQL (Supabase / PostgreSQL)
--
-- Como usar:
-- 1. Crie um projeto gratuito em https://supabase.com
-- 2. Abra "SQL Editor" no menu lateral do projeto
-- 3. Cole TODO este arquivo e clique em "Run"
-- 4. Em Project Settings -> API, copie a "Project URL" e a chave
--    "anon public" e cole no app, no ícone "Banco de dados"
--    (barra lateral) ou em Relatórios -> Conectar banco de dados.
--
-- Já rodou este script antes? Pode rodar de novo sem medo: todos os
-- comandos usam "if not exists" / "on conflict do nothing", então
-- atualizações (como a tabela class_representatives ou a coluna
-- whatsapp) são adicionadas sem apagar ou duplicar nada que já existe.
--
-- IMPORTANTE SOBRE SEGURANÇA:
-- Como o sistema não tem tela de login (por desenho, para uso de
-- uma única pessoa), as políticas abaixo liberam leitura e escrita
-- para a chave "anon" (a chave pública usada pelo navegador). Isso
-- significa que qualquer pessoa que tiver a URL do seu projeto E a
-- chave anon conseguiria ler/alterar os dados. A chave anon não é
-- secreta por natureza, mas evite publicar essas credenciais em
-- lugares públicos (ex.: repositório GitHub público). Se no futuro
-- você quiser exigir login, basta trocar as policies "USING (true)"
-- abaixo por regras baseadas em auth.uid().
-- ============================================================

create table if not exists classes (
  id text primary key,
  name text not null,
  day_index int not null,
  note text default ''
);

-- se a tabela classes já existia de uma versão anterior deste script
alter table classes add column if not exists note text default '';

create table if not exists groups (
  id text primary key,
  class_id text not null references classes(id),
  name text not null,
  status text not null default 'ativo',
  leader_id text,
  group_grade numeric,
  created_at date
);

create table if not exists students (
  id text primary key,
  name text not null,
  rgm text not null,
  class_id text not null references classes(id),
  group_id text,
  status text not null default 'ativo',
  observations text default '',
  whatsapp text default '',
  created_at date
);

-- se a tabela students já existia de uma versão anterior deste script, garante a coluna nova
alter table students add column if not exists whatsapp text default '';

create table if not exists individual_grades (
  id text primary key,
  student_id text not null,
  class_id text,
  group_id text,
  value numeric not null,
  label text,
  date date
);

create table if not exists group_grades_history (
  id text primary key,
  group_id text not null,
  value numeric not null,
  date date
);

create table if not exists diary_entries (
  id text primary key,
  date date not null,
  class_id text,
  group_id text,
  student_id text,
  category text not null,
  description text not null,
  created_at_ms bigint
);

create table if not exists group_history (
  id text primary key,
  group_id text not null,
  class_id text,
  date date,
  description text
);

create table if not exists student_history (
  id text primary key,
  student_id text not null,
  date date,
  from_group_id text,
  to_group_id text,
  description text
);

create table if not exists categories (
  name text primary key
);

create table if not exists app_meta (
  id text primary key default 'singleton',
  is_demo boolean default true
);

create table if not exists class_representatives (
  id text primary key,
  class_id text not null references classes(id),
  student_id text not null,
  created_at date
);

create table if not exists events (
  id text primary key,
  date date not null,
  title text not null,
  description text default '',
  created_at_ms bigint
);

-- índices úteis para os filtros mais comuns
create index if not exists idx_groups_class on groups(class_id);
create index if not exists idx_students_class on students(class_id);
create index if not exists idx_students_group on students(group_id);
create index if not exists idx_individual_grades_student on individual_grades(student_id);
create index if not exists idx_diary_class on diary_entries(class_id);
create index if not exists idx_diary_group on diary_entries(group_id);
create index if not exists idx_group_history_group on group_history(group_id);
create index if not exists idx_student_history_student on student_history(student_id);
create index if not exists idx_class_reps_class on class_representatives(class_id);
create index if not exists idx_events_date on events(date);

-- ============================================================
-- RLS: liberado para a chave anon (sem login), uso individual.
-- ============================================================
alter table classes enable row level security;
alter table groups enable row level security;
alter table students enable row level security;
alter table individual_grades enable row level security;
alter table group_grades_history enable row level security;
alter table diary_entries enable row level security;
alter table group_history enable row level security;
alter table student_history enable row level security;
alter table categories enable row level security;
alter table app_meta enable row level security;
alter table class_representatives enable row level security;
alter table events enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['classes','groups','students','individual_grades','group_grades_history','diary_entries','group_history','student_history','categories','app_meta','class_representatives','events']
  loop
    execute format('drop policy if exists "allow anon all" on %I;', t);
    execute format('create policy "allow anon all" on %I for all to anon using (true) with check (true);', t);
  end loop;
end $$;

-- seed inicial das 6 turmas fixas e categorias padrão do diário
insert into classes (id, name, day_index) values
  ('seg','Segunda-feira',0),
  ('ter','Terça-feira',1),
  ('qua','Quarta-feira',2),
  ('qui','Quinta-feira',3),
  ('sex','Sexta-feira',4),
  ('sab','Sábado',5)
on conflict (id) do nothing;

insert into categories (name) values
  ('Comportamento'),('Desempenho'),('Participação'),('Liderança'),
  ('Conflito'),('Problema'),('Destaque positivo'),('Organização'),('Outro')
on conflict (name) do nothing;

insert into app_meta (id, is_demo) values ('singleton', false)
on conflict (id) do nothing;
