# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WikiMapper is a browser extension for Chrome and Firefox that tracks and visualizes Wikipedia browsing sessions. It creates a historical tree showing how users navigate through Wikipedia articles. The extension runs in the background and stores all data locally.

## Essential Commands

### Build and Development
- `npm run build` - Build for Chrome, Firefox, and Safari (creates `/dist/chrome`, `/dist/firefox`, and Safari extension in `WikiMapper/Shared (Extension)/`)
- `npx grunt build:chrome` - Build only Chrome extension
- `npx grunt build:firefox` - Build only Firefox extension  
- `npx grunt build:safari` - Build only Safari extension
- `npm run lint` - Run ESLint for code quality
- `npm run test` - Run Jest tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:coverage` - Run tests with coverage report
- `xcodebuild -scheme "WikiMapper (macOS)" -configuration Debug build` - Compile macOS version
- `xcodebuild -scheme "WikiMapper (iOS)" -configuration Debug build` - Compile iOS version

### Installation for Testing
1. `npm install`
2. `npm run build`
3. Chrome: Load unpacked extension from `/dist/chrome` in chrome://extensions
4. Firefox: Load `/dist/wikimapper-firefox.zip` in about:addons > Debug Add-ons
5. Safari: Open `WikiMapper/WikiMapper.xcodeproj` in Xcode, build and run the app, then enable the extension in Safari preferences

## Architecture

### Core Components
- **Background Script** (`src/chrome/background.js`): Service worker handling webNavigation events
- **Web App** (`src/web/`): Backbone.js frontend for visualization
- **Session Handler** (`src/chrome/session-handler.js`): Manages browsing sessions
- **Storage** (`src/chrome/storage.js`): Local data persistence

### Frontend Structure (Backbone.js MVC)
- Models in `src/web/js/models/`
- Views in `src/web/js/views/` 
- Collections in `src/web/js/collections/`
- Handlebars templates in `src/web/templates/`

### Build System
Uses Grunt with these key tasks:
- Clean previous builds
- Copy manifests and resources to browser-specific directories
- Compile LESS to CSS
- Webpack bundling with Babel transpilation
- Template compilation (Handlebars)

### Browser Compatibility
- Separate manifests: `manifest.chrome.json` and `manifest.firefox.json`
- Uses `webextension-polyfill` for cross-browser API compatibility
- Supports Manifest v3 standard

### Dependencies
- **Frontend**: Backbone.js, jQuery, D3.js v3.5.17, Day.js
- **Build**: Webpack 5, Grunt, Babel, Less
- **Testing**: Jest with jsdom environment

## Testing
- Tests located in `/test/` directory
- Uses Jest with jsdom for browser environment simulation
- WebExtension APIs are mocked for testing
- Run single test file: `npx jest test/filename.test.js`

## Key Files
- `Gruntfile.js` - Build configuration
- `webpack.config.js` - Module bundling setup
- `babel.config.js` - ES6+ transpilation
- `jest.config.js` - Test configuration
- `.eslintrc.json` - Code quality rules