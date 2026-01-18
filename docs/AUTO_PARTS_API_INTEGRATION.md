# Auto Parts API Integration

## Overview
Integrated RapidAPI Auto Parts Catalog to search and add vehicle parts to your inventory system.

## What Was Added

### 1. **API Service** (`lib/core/services/auto_parts_api_service.dart`)
- **AutoPartsApiService**: Main service class for API communication
- **Methods**:
  - `searchParts(keyword)`: Search parts by keyword
  - `getPartDetails(articleId)`: Get detailed part information
  - `getPartsByVehicle(brand, model, year)`: Filter parts by vehicle

### 2. **Search Screen** (`lib/presentation/screens/inventory/auto_parts_search_screen.dart`)
- Beautiful search interface for browsing auto parts catalog
- Features:
  - Real-time search with keyword
  - Part details display (brand, part number, category)
  - Add to inventory with custom pricing
  - Quantity management

### 3. **Integration**
- Added "Search Catalog" button (cloud download icon) in Inventory screen AppBar
- Only visible to users with `manageInventory` permission

## How to Use

### For Admin Users:
1. Navigate to **Inventory** screen
2. Click the **cloud download icon** in the top-right corner
3. Enter a search term (e.g., "brake pads", "oil filter", "spark plug")
4. Click **Search**
5. Browse results and click **Add** on any part
6. Set:
   - Quantity
   - Purchase Price
   - Selling Price
7. Click **Add** to save to inventory

## API Details

**Provider**: RapidAPI Auto Parts Catalog
**Base URL**: `https://auto-parts-catalog.p.rapidapi.com`
**API Key**: Already configured in the service

### Available Endpoints:
- Search articles
- Get article details
- Filter by vehicle make/model

## Data Models

### AutoPart
```dart
{
  articleId: String,
  articleNumber: String,
  brandName: String,
  description: String,
  category: String?,
  price: double?
}
```

### AutoPartDetail
```dart
{
  articleId: String,
  articleNumber: String,
  brandName: String,
  description: String,
  category: String,
  applicableVehicles: List<String>,
  specifications: Map<String, dynamic>
}
```

## Benefits

✅ **Huge Catalog**: Access to thousands of auto parts
✅ **Accurate Data**: Professional part numbers and specifications
✅ **Time Saving**: No manual data entry for common parts
✅ **Brand Information**: Authentic brand names and part numbers
✅ **Easy Integration**: Seamlessly adds to existing inventory

## Future Enhancements

Potential improvements:
- Filter by vehicle compatibility
- Bulk import
- Price comparison
- Part images from API
- Automatic stock updates
- Supplier integration

## Technical Notes

- Uses `http` package for API calls
- Error handling for network issues
- Responsive UI with loading states
- Permission-based access control
- Integrates with existing inventory system
