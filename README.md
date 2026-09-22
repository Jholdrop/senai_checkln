# SENAI CheckIn

Aplicativo Flutter para registrar atividades de campo. Cada check-in pode reunir a data e hora, a localização GPS, uma observação e uma foto tirada pela câmera do dispositivo.

Os registros são armazenados localmente no aparelho e podem ser consultados posteriormente, inclusive com um atalho para abrir as coordenadas no mapa.

## Funcionalidades

- Captura da localização atual com GPS;
- Foto da atividade usando a câmera;
- Campo de observação para descrever a visita;
- Persistência dos registros em banco local SQLite;
- Listagem dos check-ins do mais recente para o mais antigo;
- Visualização dos detalhes, foto e coordenadas de cada registro;
- Abertura da localização no Google Maps.

## Tecnologias

| Tecnologia | Uso no projeto |
| --- | --- |
| [Flutter](https://flutter.dev/) | Interface e aplicativo multiplataforma |
| `geolocator` | Leitura da localização GPS |
| `image_picker` | Captura de fotos pela câmera |
| `permission_handler` | Solicitação de permissões do Android |
| `sqflite` | Banco de dados local SQLite |
| `url_launcher` | Abertura da localização em um aplicativo de mapas |

## Como executar

### Pré-requisitos

- Flutter SDK instalado e configurado;
- Um dispositivo Android físico ou emulador. Para testar câmera e GPS, prefira um dispositivo físico;
- Android SDK compatível com a instalação do Flutter.

### Passos

```bash
git clone <url-do-repositorio>
cd exemplo_senai_checkln
flutter pub get
flutter run
```

Para verificar se o ambiente está pronto, execute:

```bash
flutter doctor
```

## Como usar

1. Abra o aplicativo e selecione **Novo registro**.
2. Toque em **Localização GPS** e permita o acesso à localização quando solicitado.
3. Toque em **Foto da atividade** para registrar uma evidência visual (opcional).
4. Escreva uma observação sobre a visita ou atividade.
5. Selecione **Salvar registro**.
6. Toque em um item da lista para consultar os detalhes ou abrir sua posição no mapa.

> A localização GPS é obrigatória para salvar um registro. A foto e a observação são opcionais.

## Permissões do Android

O aplicativo declara as permissões abaixo em `android/app/src/main/AndroidManifest.xml` e as solicita durante o uso:

- `CAMERA`: tirar a foto da atividade;
- `ACCESS_FINE_LOCATION`: obter a posição com maior precisão;
- `ACCESS_COARSE_LOCATION`: obter a posição aproximada.

Mantenha o GPS do aparelho ativado e conceda a permissão de localização para criar um check-in.

## Armazenamento dos dados

Os dados ficam apenas no dispositivo, no banco SQLite `senai_checkin.db`. Cada registro contém:

| Campo | Descrição |
| --- | --- |
| Data e hora | Momento em que o registro foi salvo |
| Latitude e longitude | Coordenadas capturadas pelo GPS |
| Observação | Texto informado pelo usuário |
| Caminho da foto | Referência local para a imagem, quando anexada |

Não há integração com servidor ou sincronização em nuvem nesta versão.

## Estrutura principal

```text
lib/
└── main.dart       # Interface, captura de GPS/foto e banco de dados
android/
└── app/src/main/
    └── AndroidManifest.xml  # Permissões da câmera e localização
```

## Dependências

As versões exatas estão em [`pubspec.yaml`](pubspec.yaml). Para atualizar os pacotes dentro das restrições definidas, use:

```bash
flutter pub upgrade
```

## Licença

Este projeto não possui uma licença declarada. Antes de reutilizá-lo ou distribuí-lo, defina uma licença apropriada.
