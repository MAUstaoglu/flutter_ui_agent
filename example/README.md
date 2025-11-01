# flutter_ui_agent_example

Example app demonstrating the Flutter UI Agent package with multiple page types (counter, profile, Pokedex, shopping).

## Setup Instructions

### 1. Configure LLM Provider

The example supports multiple LLM providers. Choose the one you prefer:

#### Option A: Google Gemini (Free Tier Available)

1. **Copy the config template:**
   ```bash
   cd lib
   cp config.dart.example config.dart
   ```

2. **Get your Gemini API key:**
   - Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Create a free API key

3. **Configure in `config.dart`:**
   ```dart
   static const String llmProvider = 'gemini';
   static const String geminiApiKey = 'YOUR_GEMINI_KEY_HERE';
   static const String geminiModel = 'gemini-2.0-flash-exp';
   ```

#### Option B: OpenAI (Requires Payment)

1. **Copy the config template:**
   ```bash
   cd lib
   cp config.dart.example config.dart
   ```

2. **Get your OpenAI API key:**
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create an API key (requires credits/payment)

3. **Configure in `config.dart`:**
   ```dart
   static const String llmProvider = 'openai';
   static const String openaiApiKey = 'YOUR_OPENAI_KEY_HERE';
   static const String openaiModel = 'gpt-4o-mini'; // or 'gpt-4o', 'gpt-4-turbo'
   ```

#### Option C: HuggingFace 

1. **Copy the config template:**
   ```bash
   cd lib
   cp config.dart.example config.dart
   ```

2. **Get your HuggingFace API key:**
   - Visit [HuggingFace Settings - Tokens](https://huggingface.co/settings/tokens)
   - Create a free account if you don't have one
   - Click "New token" → Give it a name → Select "Read" access → Create
   - Copy your token

3. **Configure in `config.dart`:**
   ```dart
   static const String llmProvider = 'huggingface';
   static const String huggingfaceApiKey = 'YOUR_HUGGINGFACE_TOKEN_HERE';
   static const String huggingfaceModel = 'meta-llama/Meta-Llama-3-70B-Instruct';
   ```

**HuggingFace Notes:**
- ✅ **100% Free** - No payment required, unlimited requests (with rate limits)
- ⏰ **First request slow** - Models take 20-30 seconds to load initially
- 🚀 **Subsequent requests fast** - Once loaded, models respond quickly
- 🔧 **Alternative models**: 
  - `mistralai/Mistral-7B-Instruct-v0.2` (faster, smaller)
  - `microsoft/Phi-3-mini-4k-instruct` (fastest, most compact)

#### Option D: Mock Mode (No API Needed)

For testing without an API key:

```dart
static const String llmProvider = 'mock';
```

**Note:** The `config.dart` file is in `.gitignore` and will not be committed to Git.

### 2. Run the Example

```bash
flutter pub get
flutter run
```

## Features Demonstrated

- **Counter Page**: Simple increment/decrement actions
- **Profile Page**: Bio updates, status changes, navigation
- **Pokedex Page**: Pokemon filtering, search
- **Shopping Page**: Product filtering, cart management, price controls

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
