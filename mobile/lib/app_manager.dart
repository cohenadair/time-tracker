import 'package:mobile/preferences_manager.dart';
import 'package:mobile/database/sqlite_data_manager.dart';

class AppManager {
  SQLiteDataManager _dataManager;
  PreferencesManager _preferencesManager;

  SQLiteDataManager get dataManager {
    if (_dataManager == null) {
      _dataManager = SQLiteDataManager();
    }
    return _dataManager;
  }

  PreferencesManager get preferencesManager {
    if (_preferencesManager == null) {
      _preferencesManager = PreferencesManager();
    }
    return _preferencesManager;
  }
}