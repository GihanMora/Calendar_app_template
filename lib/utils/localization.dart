/// Localization utility for Thai Calendar app
/// 
/// Note: Weekday names (Mon, Tue, etc.), month names, and "Edit" are kept in English
/// as per user requirements. Only UI text is translated to Thai.

class AppLocalization {
  static const Map<String, Map<String, String>> _translations = {
    'th': {
      // App
      'app_title': 'ปฏิทินไทย',
      
      // Settings
      'settings': 'การตั้งค่า',
      'appearance': 'การแสดงผล',
      'theme': 'ธีม',
      'language': 'ภาษา',
      'system_default': 'ค่าเริ่มต้นระบบ',
      'light_theme': 'ธีมสว่าง',
      'dark_theme': 'ธีมมืด',
      'thai': 'ไทย',
      'english': 'อังกฤษ',
      'theme_changed': 'เปลี่ยนธีมเป็น',
      'language_changed': 'เปลี่ยนภาษาเป็น',
      
      // Navigation & General
      'today': 'วันนี้',
      'holidays': 'วันหยุด',
      'public_holidays': 'วันหยุดราชการ',
      'next_holiday': 'วันหยุดถัดไป',
      'close': 'ปิด',
      'cancel': 'ยกเลิก',
      'save': 'บันทึก',
      'delete': 'ลบ',
      'edit': 'Edit', // Keep in English
      'watch_ad': 'ดูโฆษณา',
      
      // Notes
      'my_notes': 'บันทึกของฉัน',
      'no_notes': 'ยังไม่มีบันทึก',
      'add_note': 'เพิ่มบันทึก',
      'delete_note': 'ลบบันทึก',
      'delete_note_confirm': 'คุณต้องการลบบันทึกนี้หรือไม่?',
      'note_saved': 'บันทึกแล้ว',
      'note_deleted': 'ลบบันทึกแล้ว',
      'enter_note': 'ป้อนบันทึกของคุณ...',
      'annual': 'ประจำปี',
      'notification_set': 'ตั้งการแจ้งเตือนแล้ว',
      'notification_not_set': 'ยังไม่ได้ตั้งการแจ้งเตือน',
      
      // Notifications
      'notifications': 'การแจ้งเตือน',
      'notification_permission': 'สิทธิ์การแจ้งเตือน',
      'notification_enabled': 'เปิดใช้งานแล้ว',
      'notification_disabled': 'ปิดใช้งานแล้ว',
      'request_permission': 'ขอสิทธิ์',
      'enable_notifications': 'เปิดการแจ้งเตือน',
      'notification_settings': 'การตั้งค่าการแจ้งเตือน',
      'notification_time': 'เวลาแจ้งเตือน',
      'days_before_event': 'วันก่อนเหตุการณ์',
      'time': 'เวลา',
      'notify_all_holidays': 'แจ้งเตือนวันหยุดทั้งหมด',
      'notify_all_holidays_desc': 'รับการแจ้งเตือนวันหยุดราชการทั้งหมด',
      'holiday_notifications_enabled': 'เปิดการแจ้งเตือนวันหยุดแล้ว',
      'holiday_notifications_disabled': 'ปิดการแจ้งเตือนวันหยุดแล้ว',
      'notification_settings_saved': 'บันทึกการตั้งค่าการแจ้งเตือนแล้ว',
      'permission_granted': 'ได้รับสิทธิ์การแจ้งเตือนแล้ว',
      'permission_denied': 'ปฏิเสธสิทธิ์การแจ้งเตือน',
      'checking': 'กำลังตรวจสอบ...',
      'day_before': 'วันก่อน',
      'days_before': 'วันก่อน',
      'on_the_day': 'ในวันนั้น',
      
      // School Holidays
      'school_holidays': 'วันหยุดโรงเรียน',
      'show_school_holidays': 'แสดงวันหยุดโรงเรียน',
      'school_holidays_desc': 'แสดงช่วงวันหยุดโรงเรียนในปฏิทิน',
      'school_holidays_enabled': 'เปิดแสดงวันหยุดโรงเรียนแล้ว',
      'school_holidays_disabled': 'ปิดแสดงวันหยุดโรงเรียนแล้ว',
      
      // State/Region
      'state_territory': 'รัฐ/เขต',
      'select_state': 'เลือกรัฐ/เขต',
      'showing_holidays_for': 'แสดงวันหยุดสำหรับ',
      
      // Year Format
      'year_format': 'รูปแบบปี',
      'year_format_desc': 'เลือกการแสดงปี',
      'buddhist_era': 'พุทธศักราช (พ.ศ.)',
      'international': 'คริสต์ศักราช (ค.ศ.)',
      'year_format_changed': 'เปลี่ยนรูปแบบปีเป็น',
      'be_suffix': 'พ.ศ.',
      'ad_suffix': 'ค.ศ.',
      
      // About
      'about': 'เกี่ยวกับ',
      'version': 'เวอร์ชัน',
      
      // Debug
      'debug_notifications': 'ตรวจสอบการแจ้งเตือน',
      'debug_notifications_desc': 'ตรวจสอบการแจ้งเตือนที่รอดำเนินการ',
      
      // Theme dialog
      'theme_change': 'เปลี่ยนธีม',
      'watch_ad_message': 'กรุณาดูโฆษณาเพื่อดำเนินการต่อ',
      'ad_not_available': 'โฆษณาไม่พร้อมใช้งาน กรุณาลองอีกครั้ง',
      
      // Weekdays - Keep in English as per requirement
      'monday': 'MON',
      'tuesday': 'TUE',
      'wednesday': 'WED',
      'thursday': 'THU',
      'friday': 'FRI',
      'saturday': 'SAT',
      'sunday': 'SUN',
      
      // Month names - Keep in English as per requirement
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',
      
      // Misc
      'no_special_notes': 'ไม่มีบันทึกพิเศษ',
    },
    'en': {
      // App
      'app_title': 'Thai Calendar',
      
      // Settings
      'settings': 'Settings',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'language': 'Language',
      'system_default': 'System Default',
      'light_theme': 'Light Theme',
      'dark_theme': 'Dark Theme',
      'thai': 'Thai',
      'english': 'English',
      'theme_changed': 'Theme changed to',
      'language_changed': 'Language changed to',
      
      // Navigation & General
      'today': 'Today',
      'holidays': 'Holidays',
      'public_holidays': 'Public Holidays',
      'next_holiday': 'Next Holiday',
      'close': 'Close',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'watch_ad': 'Watch Ad',
      
      // Notes
      'my_notes': 'My Notes',
      'no_notes': 'No notes yet',
      'add_note': 'Add Note',
      'delete_note': 'Delete Note',
      'delete_note_confirm': 'Are you sure you want to delete this note?',
      'note_saved': 'Note saved',
      'note_deleted': 'Note deleted',
      'enter_note': 'Enter your note...',
      'annual': 'Annual',
      'notification_set': 'Notification set',
      'notification_not_set': 'Notification not set',
      
      // Notifications
      'notifications': 'Notifications',
      'notification_permission': 'Notification Permission',
      'notification_enabled': 'Enabled',
      'notification_disabled': 'Disabled',
      'request_permission': 'Request',
      'enable_notifications': 'Enable Notifications',
      'notification_settings': 'Notification Settings',
      'notification_time': 'Notification Time',
      'days_before_event': 'Days before event',
      'time': 'Time',
      'notify_all_holidays': 'Notify for All Holidays',
      'notify_all_holidays_desc': 'Get notifications for all public holidays',
      'holiday_notifications_enabled': 'Holiday notifications enabled',
      'holiday_notifications_disabled': 'Holiday notifications disabled',
      'notification_settings_saved': 'Notification settings saved',
      'permission_granted': 'Notification permission granted',
      'permission_denied': 'Notification permission denied',
      'checking': 'Checking...',
      'day_before': 'day before',
      'days_before': 'days before',
      'on_the_day': 'On the day',
      
      // School Holidays
      'school_holidays': 'School Holidays',
      'show_school_holidays': 'Show School Holidays',
      'school_holidays_desc': 'Display school holiday ranges on calendar',
      'school_holidays_enabled': 'School holidays enabled',
      'school_holidays_disabled': 'School holidays disabled',
      
      // State/Region
      'state_territory': 'State/Territory',
      'select_state': 'Select State/Territory',
      'showing_holidays_for': 'Showing holidays for',
      
      // Year Format
      'year_format': 'Year Format',
      'year_format_desc': 'Choose year display format',
      'buddhist_era': 'Buddhist Era (BE)',
      'international': 'International (AD)',
      'year_format_changed': 'Year format changed to',
      'be_suffix': 'BE',
      'ad_suffix': 'AD',
      
      // About
      'about': 'About',
      'version': 'Version',
      
      // Debug
      'debug_notifications': 'Debug Notifications',
      'debug_notifications_desc': 'Check pending notifications and settings',
      
      // Theme dialog
      'theme_change': 'Theme change',
      'watch_ad_message': 'In order to do this, please watch a rewarded ad.',
      'ad_not_available': 'Ad not available. Please try again later.',
      
      // Weekdays
      'monday': 'MON',
      'tuesday': 'TUE',
      'wednesday': 'WED',
      'thursday': 'THU',
      'friday': 'FRI',
      'saturday': 'SAT',
      'sunday': 'SUN',
      
      // Month names
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',
      
      // Misc
      'no_special_notes': 'No special notes',
    },
  };

  static String getText(String key, String language) {
    return _translations[language]?[key] ?? _translations['en']![key] ?? key;
  }

  static List<String> getWeekdays(String language) {
    // Always return English weekday abbreviations as per requirement
    return [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];
  }

  static String getMonthName(int month, String language) {
    // Always return English month names as per requirement
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return 'January';
    }
  }

  static String getWeekdayName(int weekday, String language) {
    // weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
    // Always return English as per requirement
    final weekdays = getWeekdays(language);
    final weekdayIndex = (weekday - 1) % 7;
    return weekdays[weekdayIndex];
  }

  static String getFullWeekdayName(int weekday, String language) {
    // Always return English full weekday names as per requirement
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }
}
