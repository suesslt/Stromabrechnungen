# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Stromabrechnungen is an iOS/macOS app for managing electricity costs in energy communities (Eigenverbrauchsgemeinschaften). It automates proportional distribution of power utility bills among residents/shareholders and generates Swiss QR-Bill invoices. German-language UI.

## Build & Test Commands

```bash
# Build
xcodebuild -project Stromabrechnungen.xcodeproj -scheme Stromabrechnungen build

# Run tests
xcodebuild -project Stromabrechnungen.xcodeproj -scheme Stromabrechnungen test
```

## Architecture

- **SwiftUI + SwiftData** for persistence (iOS 17+, macOS 14+)
- Integrates with **SwissInvoice** package for QR-Bill generation
- Model-to-DTO conversion (Bezugspartei → Address for SwissInvoice)
- Decimal arithmetic for precise financial calculations
- Template-based text resolution for dynamic invoice content

### Key Models

| Model | Role |
|-------|------|
| `Stromabrechnung` | Utility bill record |
| `Stromgemeinschaft` | Energy community |
| `Bezugspartei` | Customer/recipient |
| `Parteienrechnung` | Invoice to customer |
| `Parteienabrechnung` | Cost distribution |

### Services
- `ClaudeService` — PDF analysis with Claude API for automated bill data extraction

## Score Package — Shared Base Classes

This project depends on the [Score](../score) package via local SPM dependency (`../score`).

**Current usage**: `import Score` for `Money` (CHF currency amounts in billing calculations).

### Available Types

| Type | Module | Description |
|------|--------|-------------|
| `Money` | Score | Currency-safe monetary amounts with `Decimal` precision. Arithmetic enforces matching currencies. |
| `Currency` | Score | ISO 4217 enum with 180+ currencies, decimal places, and localized names. |
| `Percent` | Score | Percentage as factor (e.g. `0.10` = 10%). |
| `FXRate` | Score | Bid/ask exchange rates with conversion methods. |
| `VATCalculation` | Score | VAT split (net/gross) with inclusive/exclusive handling. |
| `YearMonth` | Score | Year-month value type for monthly periods. |
| `DayCountRule` | Score | Financial day count conventions (ACT/360, ACT/365, 30/360). |
| `ServicePipeline` | Score | Async middleware chain for service operations. |
| `ServiceError` | Score | Typed errors (notFound, validation, businessRule, etc.). |
| `CSVExportable` | Score | Protocol for CSV row export. |
| `IBANValidator` | Score | ISO 13616 IBAN validation. |
| `SCORReferenceGenerator` | Score | ISO 11649 creditor reference with Mod 97. |
| `ErrorHandler` | ScoreUI | Observable error state management for SwiftUI. |
| `PDFRenderer` | ScoreUI | UIKit-based PDF generation. |
| `.errorAlert()` | ScoreUI | SwiftUI modifier for error alert presentation. |

```swift
import Score    // Money, Currency, VATCalculation, etc.
```
