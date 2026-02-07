# 🔔 Notification System Guide - Duka Kiganjani

## What's Included

The app now has **Local Notifications** that work offline and provide important alerts in Swahili.

## Features Implemented

### 1. **Low Stock Alerts** 🔴
- Automatically checks when you open inventory
- Sends notification when products are running low
- Example: "⚠️ Bidhaa Zinakaribia Kuisha! Mchele zimebaki 5 tu (kiwango cha chini: 10)"

### 2. **Daily Sales Summary** 📊
- Can be triggered manually
- Shows total sales and transaction count
- Example: "📊 Muhtasari wa Mauzo ya Leo - Jumla: TZS 250,000 | Mauzo: 45"

### 3. **Debt Reminders** 💰
- Reminds about unpaid debts
- Example: "💰 Madeni Yasiyolipwa - Una madeni 5 ya jumla TZS 50,000"

### 4. **Daily Reminders** ⏰ (Optional)
- Opening reminder at 8:00 AM: "🌅 Habari za Asubuhi! Ni wakati wa kufungua duka"
- Closing reminder at 6:00 PM: "🌙 Muhtasari wa Leo - Ni wakati wa kufunga duka"

## How It Works

### Automatic Notifications:
- **Low stock alerts** trigger automatically when viewing inventory
- Checks each product against its low stock threshold

### Manual Notifications (Future Features):
You can add buttons to trigger:
```dart
// In reports page
NotificationService().showDailySalesSummary(
  totalSales: 250000,
  transactionCount: 45,
);

// In debts page
NotificationService().showDebtReminder(
  debtCount: 5,
  totalDebt: 50000,
);
```

### Scheduled Reminders:
Uncomment in `main.dart` to enable:
```dart
await notificationService.scheduleOpeningReminder(); // 8:00 AM
await notificationService.scheduleClosingReminder();  // 6:00 PM
```

## Testing Notifications

1. **Test Low Stock:**
   - Add a product with low stock (quantity ≤ low stock alert)
   - Open inventory page
   - Should see notification

2. **Test Manual Notification:**
   Add test button in any page:
   ```dart
   ElevatedButton(
     onPressed: () {
       NotificationService().showNotification(
         id: 999,
         title: 'Test Notification',
         body: 'Majaribio ya notification!',
       );
     },
     child: Text('Test Notification'),
   )
   ```

## Permissions

Already configured in AndroidManifest.xml:
- ✅ POST_NOTIFICATIONS (Android 13+)
- ✅ SCHEDULE_EXACT_ALARM
- ✅ USE_EXACT_ALARM

## Future Enhancements

### Easy to Add:
1. **Weekly Sales Report** - Every Monday morning
2. **Stock Expiry Alerts** - Products expiring soon
3. **Employee Activity** - When employee makes sale
4. **Goal Achievements** - When daily/monthly target met
5. **Payment Reminders** - For overdue debts

### How to Add Custom Notification:
```dart
NotificationService().showNotification(
  id: 123,  // Unique ID
  title: 'Your Title in Swahili',
  body: 'Your message here',
  payload: 'optional_data', // Use for navigation
);
```

## Troubleshooting

### Notifications not showing?
1. Check phone Settings → Apps → Duka Kiganjani → Notifications (must be enabled)
2. Ensure app has notification permission
3. Check if battery saver is blocking notifications

### Want to disable notifications?
Comment out in `inventory.dart`:
```dart
// _checkLowStockAndNotify();
```

## Benefits

✅ **Works Offline** - No internet needed
✅ **Free** - No external services or costs
✅ **Battery Friendly** - Uses native Android notifications
✅ **Swahili Language** - All notifications in Swahili
✅ **Customizable** - Easy to add more notification types

## Next Steps

Ready to use! The system is:
- ✅ Installed and configured
- ✅ Testing low stock alerts on inventory load
- ⏸️ Daily reminders disabled by default (can enable anytime)

**Test it now:** Add a product with low stock and open inventory!
