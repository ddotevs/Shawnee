# Shawnee

A dynamic, read-only Roku channel for displaying local information - perfect for vacation rentals, Airbnb properties, hotels, or visitor centers.

## Features

- 📱 **Dynamic JSON Content** - All content loaded from a single JSON file
- 📂 **Category Navigation** - Organized sections (House Info, Things To Do, Places To Eat, etc.)
- 🖼️ **Visual Tiles** - Image, title, and description for each item
- 📄 **Detail Views** - Full information panel with address, phone, hours, tips, and more
- 🚨 **Emergency Highlighting** - Important items visually distinguished
- 🎨 **Modern Dark UI** - Clean, TV-optimized interface

## Project Structure

```
Shawnee/
├── manifest                      # Channel configuration
├── source/
│   └── main.brs                 # Entry point
├── components/
│   ├── MainScene.xml/.brs       # Main navigation scene
│   ├── ItemTile.xml/.brs        # Grid tile component
│   ├── DetailPanel.xml/.brs     # Full-screen detail view
│   └── tasks/
│       └── ContentTask.xml/.brs # JSON content loader
├── content/
│   └── content.json             # All channel content (edit this!)
├── images/                      # Channel artwork and icons
└── fonts/                       # Custom fonts (optional)
```

## Content Schema

Edit `content/content.json` to customize your channel. Here's the full data schema:

### Channel Configuration
```json
{
  "channel": {
    "name": "Your Channel Name",
    "welcomeMessage": "Welcome message displayed in header",
    "propertyName": "Property name",
    "backgroundImage": "pkg:/images/background.jpg",
    "accentColor": "#e94560",
    "lastUpdated": "2024-12-16"
  }
}
```

### Categories
```json
{
  "categories": [
    {
      "id": "unique-id",
      "title": "Category Title",
      "icon": "pkg:/images/icons/category.png",
      "description": "Category description",
      "sortOrder": 1,
      "items": [...]
    }
  ]
}
```

### Item Fields (All Optional Except id, title)

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier |
| `title` | string | Display name |
| `shortDescription` | string | Tagline for tiles |
| `description` | string | Full description |
| `image` | string | Large image path |
| `icon` | string | Small icon path |
| `address` | string | Physical location |
| `distance` | string | Distance from property |
| `phone` | string | Contact number |
| `website` | string | URL |
| `hours` | string | Operating hours |
| `priceRange` | string | $, $$, $$$ |
| `priceDetails` | object | Detailed pricing |
| `rating` | number | 1-5 star rating |
| `cuisineType` | string | Restaurant cuisine |
| `tags` | array | Searchable tags |
| `dietaryOptions` | array | Vegetarian, GF, etc. |
| `amenities` | array | Available features |
| `reservationRequired` | boolean | Needs booking? |
| `reservationUrl` | string | Booking link |
| `tips` | string | Insider advice |
| `isEmergency` | boolean | Highlight as urgent |
| `sortOrder` | number | Display order |
| `details` | object | Custom structured data |
| `contacts` | array | Emergency contacts |
| `rules` | array | House rules list |
| `appliances` | array | Appliance instructions |

### Special Item Types

**House Info Items** can include:
```json
{
  "details": {
    "networkName": "WiFi-Name",
    "password": "wifi-password",
    "checkInTime": "3:00 PM",
    "checkOutTime": "11:00 AM",
    "keyLocation": "Lockbox code: 1234"
  },
  "contacts": [
    {"name": "Emergency", "phone": "911", "available": "24/7"}
  ],
  "rules": ["No smoking", "No parties"],
  "appliances": [
    {"name": "Coffee Maker", "brand": "Keurig", "instructions": "K-cups in drawer"}
  ]
}
```

**Restaurant Items** can include:
```json
{
  "cuisineType": "Italian",
  "dietaryOptions": ["vegetarian", "gluten-free"],
  "deliveryAvailable": true,
  "happyHour": "Mon-Fri 4-6pm"
}
```

**Activity Items** can include:
```json
{
  "bestTimeToVisit": "Early morning",
  "reservationUrl": "https://example.com/book",
  "events": "Live music Saturdays"
}
```

## Required Images

Add these images to `/images/`:

### Channel Branding
| File | Size | Purpose |
|------|------|---------|
| `channel-poster_hd.png` | 540x405 | Channel tile (focused) |
| `channel-poster_side_hd.png` | 108x81 | Channel tile (side) |
| `splash_hd.png` | 1920x1080 | HD splash screen |
| `splash_sd.png` | 720x480 | SD splash screen |
| `placeholder.png` | 280x100 | Default tile image |

### Category Icons (`/images/icons/`)
- `house.png`, `activities.png`, `dining.png`, `services.png`
- `wifi.png`, `clock.png`, `car.png`, `emergency.png`
- `hiking.png`, `coffee.png`, `steak.png`, etc.

### Content Images
- `/images/house/` - House info images
- `/images/activities/` - Activity images
- `/images/dining/` - Restaurant images
- `/images/services/` - Service images

## Development

### Enable Developer Mode on Roku
1. Press: **Home 3x, Up 2x, Right, Left, Right, Left, Right**
2. Note IP address and set password
3. Navigate to `http://<roku-ip>` in browser

### Sideload the Channel
```bash
cd Shawnee
zip -r ../shawnee.zip . -x "*.DS_Store" -x "*.git*" -x "README.md"
# Upload zip to http://<roku-ip>
```

### VS Code Extension (Recommended)
1. Install [BrightScript Language Extension](https://marketplace.visualstudio.com/items?itemName=RokuCommunity.brightscript)
2. Configure `launch.json` with Roku IP
3. Press F5 to deploy and debug

## Customization

### Change Colors
Edit the color values in component XML files:
- Background: `#1a1a2e`
- Accent: `#e94560`
- Cards: `#16213e`
- Text: `#ffffff`, `#cccccc`, `#888888`

### Add New Categories
1. Add category object to `content.json`
2. Add corresponding icon to `/images/icons/`
3. Category appears automatically!

### Add New Item Fields
1. Add field to item in `content.json`
2. Update `DetailPanel.brs` to display it

## License

This project is provided as a template for Roku channel development.
