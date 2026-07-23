# Backend PDM Mobile Softinsa

Este é o backend próprio do projeto mobile PDM da Softinsa. O backend destina-se exclusivamente ao perfil Consultor e fornece uma API REST para a aplicação Flutter.

Este serviço liga-se à mesma base PostgreSQL principal do sistema PINT. O Sequelize é utilizado apenas para comunicar com a PostgreSQL; este backend não utiliza `sequelize.sync`, não gere a estrutura da base de dados e não cria nem altera tabelas.

O ficheiro `.env` real não deve ser publicado. É necessário configurar `JWT_SECRET` localmente para a autenticação funcionar.

## Configuração Local

1. Copiar `.env.example` para `.env`.
2. Preencher localmente as credenciais e `JWT_SECRET`.
3. Executar `npm.cmd install`.
4. Executar `npm.cmd run dev`.

Por omissão, os tokens usam:

```text
JWT_ACCESS_EXPIRES_IN=8h
JWT_REFRESH_EXPIRES_IN=365d
```

O access token é usado no header `Authorization` para rotas protegidas:

```text
Authorization: Bearer <access_token>
```

O refresh token permite pedir um novo access token sem devolver um novo refresh token nesta fase.

## Endpoints

### GET /api/health

Verifica se o serviço HTTP está disponível.

### POST /api/login

Inicia sessão exclusivamente para utilizadores com role Consultor.

Body:

```json
{
  "email": "consultor@example.com",
  "password": "Password1!"
}
```

Se for primeiro acesso, não são emitidos tokens e a resposta indica `requiresPasswordChange: true`.

Se não for primeiro acesso, devolve access token, refresh token e dados básicos do Consultor.

### POST /api/primeiro-acesso

Define a nova palavra-passe no primeiro acesso e aceita as políticas RGPD.

Body:

```json
{
  "email": "consultor@example.com",
  "password": "Password1!",
  "confirmPassword": "Password1!"
}
```

Não emite tokens automaticamente.

### POST /api/esqueci-password

Atualiza a palavra-passe de um Consultor ativo.

Body:

```json
{
  "email": "consultor@example.com",
  "password": "Password1!",
  "confirmPassword": "Password1!"
}
```

Não altera `primeiro_login` nem `aceitacao_politicas`.

### POST /api/refresh-token

Emite um novo access token a partir de um refresh token válido.

Body:

```json
{
  "refreshToken": "<refresh_token>"
}
```

### GET /api/getuser

Rota protegida. Obtém os dados do Consultor autenticado a partir do access token.

Header:

```text
Authorization: Bearer <access_token>
```

### PUT /api/putlastlogin

Rota protegida. Atualiza `last_login` e `update_user` no `utilizador` e no `consultor` autenticado.

Header:

```text
Authorization: Bearer <access_token>
```

### PUT /api/aceitar-rgpd

Rota protegida. Marca as políticas RGPD como aceites no `utilizador` e no `consultor` autenticado.

Header:

```text
Authorization: Bearer <access_token>
```

## Regras de Autenticação

Todas as rotas de autenticação são exclusivas para o perfil Consultor. O backend valida a role pelo nome `Consultor`, não por um ID fixo.

As respostas nunca devolvem passwords, hashes, connection strings, `JWT_SECRET`, stack traces ou detalhes internos do Sequelize.
