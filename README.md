# DreamsIdeAura – Flutter starter

A local-first Flutter starter for a crochet business manager.

## Included in this starter

- Flutter app entry point and initial dashboard shell.
- Feature-first Clean Architecture folder layout.
- Domain entities for members, investments, products and profit configuration.
- A pure-Dart profit calculator with integer-paise arithmetic and deterministic remainder allocation.
- Local JSON file storage using the app documents directory (`path_provider`).
- Initial 40% investor / 40% efforts / 20% marketing configuration.

## Business rules encoded

- Investor pool: active members with at least one investment record.
- Effort and marketing pools: selected active contributors for that product.
- Empty category: that category's share goes equally to all active members.
- Same person may receive shares in multiple categories.
- Selling price is the distributable amount in version 1; costs are not deducted.
- Calculations are derived on demand, so current percentages and records apply dynamically to historical products.
- Currency is stored as integer paise to avoid floating-point allocation errors.

## Run

1. Install Flutter and Android Studio / VS Code Flutter tooling.
2. Extract this folder.
3. From this folder run:

   ```bash
   flutter pub get
   flutter run
   ```

## Next implementation steps

1. Add repositories and JSON serialization/mapping for all entities.
2. Build member configuration CRUD and percentage configuration UI.
3. Build investment CRUD.
4. Build product CRUD with member multi-select dropdowns.
5. Add product selection, individual earnings, date filters and reports.
6. Add unit tests for profit calculations and storage migrations.

This is a starter scaffold, not a complete production app. The dashboard cards are placeholders until the feature screens and repository wiring are implemented.
