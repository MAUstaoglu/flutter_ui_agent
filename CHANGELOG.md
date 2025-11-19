# Changelog

## [1.1.0] - 2025-11-19

### ✨ Enhanced Navigation Handling
- Added `isNavigation` flag to `AgentAction` for better navigation action identification.
- Introduced `continueAfterNavigation` parameter in `LlmFunctionCall` to allow LLMs to signal intent for post-navigation actions.
- Improved multi-step command processing by respecting LLM's continuation signals instead of heuristic detection.
- Updated Gemini and HuggingFace providers to handle the new `continue_after` parameter.
- Added comprehensive tests for navigation continuation logic.

## [1.0.0] - 2025-11-15

### 🚀 First Stable Release
- Graduated from beta to the first stable release of Flutter UI Agent.
- Standardized action parameters with the new `AgentActionParameter` model, including enum hints, numeric ranges, and prompt metadata shared with LLM tools.
- Added runtime validation for tool calls to block invalid or unknown parameters before they reach the UI.
- Made the optional `count` argument opt-in via `allowRepeats`, keeping tool schemas lean unless an action truly supports repetition.
- Updated the example app and README to showcase typed parameters, enum options, and repeatable actions.

## [0.1.0-beta.2] - 2025-11-02

### 🔧 Fixes
- Fixed demo GIF display on pub.dev by using absolute GitHub URL instead of relative path

## [0.1.0-beta.1] - 2025-01-30

### 🎉 Initial Beta Release

This is the first public beta release of Flutter UI Agent.

### ✨ Core Features
- **LLM-Agnostic Architecture**: Works with any LLM provider (Gemini, HuggingFace, OpenAI, etc.)
- **Dynamic Action Registration**: Wrap any widget to make it AI-controllable with `AiActionWidget`
- **Smart Navigation Tracking**: Automatic page tracking with `AgentNavigatorObserver`
- **Async Operation Support**: Handle navigation and async operations seamlessly
- **Multi-Step Commands**: Execute complex sequences like "Navigate to settings and enable dark mode"
- **Type-Safe Parameters**: Full Dart type safety with parameterized actions
- **Cancellation Support**: Cancel in-progress AI requests with immediate UI feedback

### 🎛️ Configuration
- **6 Log Levels**: `none`, `error`, `warning`, `info`, `verbose`, `debug`
- **Configurable Retry Logic**: Exponential, linear, or fixed backoff strategies
- **Analytics Support**: Track action usage and performance
- **Mock Mode**: Test without API keys using keyword-based matching
- **Debug Mode**: Detailed logging with emoji support for development

### ✅ Tested AI Models
- **Gemini**: `gemini-2.0-flash-exp`
- **HuggingFace**: `Qwen/Qwen3-235B-A22B-Instruct-2507`

### 📱 Example App Features
- Counter page with increment/decrement actions
- Profile page with bio/status updates
- Data browsing with search and filtering
- Shopping page with cart management
- Settings page with theme and AI configuration
- Floating chat overlay for natural language commands

### 🛠️ Technical Details
- Event-driven architecture using StreamController
- Frame-based action pacing for smooth UI updates
- Navigation detection with 25+ action keywords
- Modern Flutter 3.27+ APIs (no deprecated code)
- Comprehensive error handling and logging

### 📚 Documentation
- Complete README with quick start guide
- Example app with multiple use cases
- Configuration templates for easy setup
- Detailed API documentation

- Enhanced action descriptions are now used for better AI matching
- Improved error handling and user feedback

### Technical
- Added `google_generative_ai` package dependency
- Implemented function calling with Gemini's tool use API
- Created conversational response flow with AI

