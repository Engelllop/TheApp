# TheApp - Finanzas Personales con IA

Una aplicación de finanzas personales con un asesor financiero impulsado por IA.

## Características

- **Dashboard**: Vista general de tu balance y gastos mensuales
- **Registro de Transacciones**: Ingreso manual o importación desde CSV bancario
- **Categorización Automática**: La IA categoriza automáticamente tus gastos
- **Asesor IA**: Chat interactivo con recomendaciones financieras personalizadas
- **Presupuestos**: Define límites de gasto por categoría

## Estructura del Proyecto

```
TheApp/
├── src/
│   ├── mobile/          # App Flutter
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   ├── repositories/
│   │   │   │   └── services/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   └── pubspec.yaml
│   └── backend/          # API FastAPI
│       ├── main.py
│       └── requirements.txt
└── README.md
```

## Configuración

### Backend

```bash
cd src/backend
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Editar .env y agregar OPENAI_API_KEY
uvicorn main:app --reload
```

### Mobile (Flutter)

```bash
cd src/mobile
flutter pub get
flutter run
```

## Screenshots

*(Agregar screenshots del app aquí)*

## Tech Stack

- **Mobile**: Flutter + Dart
- **Backend**: FastAPI + Python
- **AI**: OpenAI GPT-4o / Claude 3.5 Sonnet
- **Storage**: SharedPreferences (local)
