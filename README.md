# Imovio (Flutter)

CRM imobiliário reescrito em Flutter a partir da app original
(`D:\APP Imobiliário\realestateapp-main\index.html`), seguindo a arquitetura do
[starter_architecture_flutter_firebase](https://github.com/bizz84/starter_architecture_flutter_firebase):
features em `lib/src/features`, camadas data / domain / application /
presentation, Riverpod com `@riverpod`, GoRouter em `lib/src/routing`.

Usa o mesmo projeto Firebase (`realestateapp-43e70`) e os mesmos caminhos no
Firestore (`users/{uid}/contactos`, `imoveis`, `pipeline`, `tarefas`,
`settings/config`), por isso os dados que já existem aparecem na app nova.

## Correr

```bash
flutter pub get
dart run build_runner build
flutter run -d chrome
```

Modo demonstração (dados de exemplo em memória, sem Firebase nem login,
para rever o visual e experimentar sem tocar nos dados reais):

```bash
flutter run -t tool/demo_main.dart -d chrome
```

Testes e análise:

```bash
flutter test
flutter analyze
```

## iOS

O iOS só compila num Mac com Xcode. Antes da primeira vez:

1. No Firebase Console, adicionar uma app iOS com o bundle id `pt.imovio.imovio`.
2. Correr `flutterfire configure --project=realestateapp-43e70` (gera a
   configuração iOS em `lib/firebase_options.dart` e o `GoogleService-Info.plist`).
3. `flutter run -d ios`.

## Firebase

- `firestore.rules` e `storage.rules` limitam cada utilizador aos seus dados.
  Publicar com `firebase deploy --only firestore:rules,storage`.
- O carregamento de fotos usa o Firebase Storage, que tem de estar ativo no
  projeto (Console > Storage).
- `firebase deploy --only hosting` publica a versão web a partir de `build/web`.

## Onde está cada coisa

| App original | Aqui |
| --- | --- |
| Login, registo, recuperar palavra-passe | `features/authentication` |
| Dashboard e KPIs | `features/dashboard` (agora com lembretes de tarefas) |
| Contactos, ficha com 3 abas, CSV, duplicar | `features/contacts` |
| Imóveis, novo imóvel, importação por link, detalhe com 3 abas, comissão | `features/properties` |
| Pipeline | `features/pipeline` (quadro Kanban com arrastar) |
| Tarefas | `features/tasks` (lista + calendário) |
| Configurações (tema, sair) | `features/settings` |
