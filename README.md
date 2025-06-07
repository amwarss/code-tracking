create by codescript - Team
discord:https://discord.gg/codescripts

the item

```lua
tracker                  = { name = "tracker", label = "Phone Tracker", weight = 0, type = "item", image = "tracking.png", unique = true, useable = false, shouldClose = false, description = "Phone Tracker"},
vpn_protection                  = { name = "vpn_protection", label = "Vpn Protection", weight = 500, type = "item", image = "vpn_protection.png", unique = true, useable = false, shouldClose = false, description = "Vpn Protection"},
```

or old

```lua
	['tracker'] = {
		['name'] = 'tracker',
		['label'] = 'Phone Tracker',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'tracker.png',
		['unique'] = true,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = "Phone Tracker",
	},
	['vpn_protection'] = {
		['name'] = 'vpn_protection',
		['label'] = 'Vpn Protection',
		['weight'] = 100,
		['type'] = 'item',
		['image'] = 'vpn_protection.png',
		['unique'] = true,
		['useable'] = false,
		['shouldClose'] = false,
		['combinable'] = nil,
		['description'] = "vpn protection",
	},

```

```lua
🇸🇦 الشرح بالعربي:
من هذا المكان يتم تحديد عدد خانات رقم الجوال الخاص بك، كمثال: إذا كنت تريد أن يكون رقم الجوال مكوّن من 10 خانات فقط، قم بتحديد ذلك هنا.

لتعديل هذا العدد، اتبع التالي:

اذهب إلى ملف الكونفيق (config)، وابحث عن المتغير phoneNumber وعدّله حسب عدد الخانات المطلوب.
➤ يوجد هذا في السطر الثامن.

بعد ذلك، اذهب إلى ملف JavaScript، وعدّل المتغير PHONE_DIGITS الموجود في السطر الثاني، ليطابق نفس عدد الخانات الذي حددته في الكونفيق.
```

```lua
🇺🇸 Explanation in English:
From here, you define how many digits your phone number should have.
For example: if you want the phone number to be 10 digits, set it here.

Work with lb-phone and qb-phone


To modify this setting, do the following:

Go to the config file, find the variable phoneNumber, and change it to the desired number of digits.
➤ This is located on line 8.

Then, go to the JavaScript file, and change the variable PHONE_DIGITS found on line 2 to match the same digit count you set in the config.
```


اخر السكربت الموجود في ملف 

[the minigame] - اخرج السكربت للريسورس
اخرجه للريسورس خارج السكربت لكي تعمل الميني قيم




© Code Script . All Rights Reserved.
