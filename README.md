# 🍺 Flutter Supabase App — Cervejeiros

Este é um aplicativo Flutter integrado ao Supabase, voltado para a comunidade de cervejeiros. Os usuários podem cadastrar cervejas, interagir com amigos, receber notificações e explorar perfis de outros cervejeiros.

## 🚀 Tecnologias utilizadas

- **Flutter** — Framework para desenvolvimento mobile multiplataforma
- **Supabase** — Backend como serviço (autenticação, banco de dados, storage)
- **Provider** — Gerenciamento de estado reativo
- **PostgreSQL** — Banco de dados relacional via Supabase
- **GitHub Actions** *(opcional)* — CI/CD para testes e builds automatizados

## 📦 Estrutura do projeto

lib/ 
├── models/ # Modelos de dados (ex: NotificacaoModel) 
├── providers/ # Providers para gerenciamento de estado 
├── screens/ # Telas principais do app 
├── services/ # Integração com Supabase e lógica de negócio 
└── main.dart # Ponto de entrada do app


## 🔐 Autenticação

A autenticação é feita via Supabase Auth. Cada usuário possui um perfil estendido na tabela `tb_cervejeiro`, que armazena nome, avatar e outras informações.

## 🔔 Notificações

As notificações são armazenadas na tabela `tb_notificacoes`, com suporte a:
- Cadastro de cervejas
- Solicitações de amizade
- Eventos e interações

A tela de notificações exibe:
- Data e hora do evento
- Mensagem personalizada
- Ícones para marcar como lida ou excluir

## 📲 Como rodar o projeto

1. Clone o repositório:

```bash
git clone https://github.com/seu-usuario/flutter-supabase-app.git
cd flutter-supabase-app

1. Instale as dependências:

flutter pub get

3. Configure o Supabase:

    Crie um projeto no Supabase

    Copie a anon key e url para o arquivo .env ou diretamente no serviço de autenticação

4. Execute o app:

flutter run

