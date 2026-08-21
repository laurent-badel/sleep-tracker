// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navToday => '今日';

  @override
  String get navHistory => '履歴';

  @override
  String get navStats => '統計';

  @override
  String get todaySettingsTooltip => '設定';

  @override
  String get todaySaved => '保存しました';

  @override
  String get metricsHeader => '指標';

  @override
  String get noteLabel => 'メモ（任意）';

  @override
  String get saveButton => '保存';

  @override
  String get historyEmpty =>
      'まだ記録がありません — 今日タブから今日を記録するか、+ をタップして過去の日を入力してください。';

  @override
  String get historyAddTooltip => '日を追加または編集';

  @override
  String get statsNotEnoughData => '統計を表示するには最低2日分の記録が必要です。';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日連続',
    );
    return '$_temp0';
  }

  @override
  String get streakStartHint => '連続記録を始めるには1日記録しましょう';

  @override
  String get streakKeepGoing => 'この調子で！';

  @override
  String statsAverages(String avg7, String avg30) {
    return '7日平均：$avg7 · 30日平均：$avg30';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsReminder => '毎日のリマインダー';

  @override
  String get settingsReminderSubtitle => 'その日の記録を忘れずに';

  @override
  String get settingsReminderTime => 'リマインダーの時間';

  @override
  String get settingsFeatures => '項目';

  @override
  String get settingsFeaturesSubtitle =>
      '記録する項目を選択してください。無効にしても過去のデータは削除されません。';

  @override
  String get settingsPermissionDenied => 'リマインダーを受け取るにはシステム設定で通知を有効にしてください';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageSystem => 'システム標準';

  @override
  String get languageEn => 'English';

  @override
  String get languageFr => 'Français';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get languageJa => '日本語';

  @override
  String get languageIt => 'Italiano';

  @override
  String get notifTitle => '毎日のチェックイン';

  @override
  String get notifBody => '睡眠、運動、ストレス、スクリーンタイムを記録しましょう。';

  @override
  String get notifChannelName => '毎日のリマインダー';

  @override
  String get notifChannelDescription => '毎日その日の記録を促すリマインダー';

  @override
  String get featureSleepRating => '睡眠';

  @override
  String get featureExerciseRating => '運動';

  @override
  String get featureSchoolStressRating => '学校のストレス';

  @override
  String get featureScreenUsageRating => 'スクリーンタイム';

  @override
  String get featureMoodRating => '気分';

  @override
  String get featureEnergyRating => 'エネルギー';

  @override
  String get featureNutritionRating => '栄養';

  @override
  String get featurePhysicalRating => '身体の痛み';

  @override
  String get featureSocialRating => '社交';

  @override
  String get featureProductivityRating => '生産性';

  @override
  String get featureWaterRating => '水分';

  @override
  String get featureCaffeineRating => 'カフェイン';

  @override
  String get featureAlcoholRating => 'アルコール';

  @override
  String get featureSmokingRating => '喫煙';

  @override
  String get featureMedicationTaken => '服薬';

  @override
  String get featureWorkdayFlag => '仕事の日';

  @override
  String get featureSleepRatingLow => '悪い';

  @override
  String get featureExerciseRatingLow => 'なし';

  @override
  String get featureSchoolStressRatingLow => '特になし';

  @override
  String get featureScreenUsageRatingLow => '画面なし';

  @override
  String get featureMoodRatingLow => '低い';

  @override
  String get featureEnergyRatingLow => '疲れ切った';

  @override
  String get featureNutritionRatingLow => '悪い';

  @override
  String get featurePhysicalRatingLow => 'なし';

  @override
  String get featureSocialRatingLow => 'なし';

  @override
  String get featureProductivityRatingLow => '低い';

  @override
  String get featureWaterRatingLow => 'ほとんどなし';

  @override
  String get featureCaffeineRatingLow => 'なし';

  @override
  String get featureAlcoholRatingLow => 'なし';

  @override
  String get featureSmokingRatingLow => 'なし';

  @override
  String get featureMedicationTakenLow => 'いいえ';

  @override
  String get featureWorkdayFlagLow => '休み';

  @override
  String get featureSleepRatingHigh => '良い';

  @override
  String get featureExerciseRatingHigh => 'たくさん';

  @override
  String get featureSchoolStressRatingHigh => 'とてもストレス';

  @override
  String get featureScreenUsageRatingHigh => '使いすぎ';

  @override
  String get featureMoodRatingHigh => '良い';

  @override
  String get featureEnergyRatingHigh => '活力がある';

  @override
  String get featureNutritionRatingHigh => '良い';

  @override
  String get featurePhysicalRatingHigh => 'ひどい';

  @override
  String get featureSocialRatingHigh => 'たくさん';

  @override
  String get featureProductivityRatingHigh => '高い';

  @override
  String get featureWaterRatingHigh => 'たくさん';

  @override
  String get featureCaffeineRatingHigh => 'たくさん';

  @override
  String get featureAlcoholRatingHigh => 'たくさん';

  @override
  String get featureSmokingRatingHigh => 'たくさん';

  @override
  String get featureMedicationTakenHigh => 'はい';

  @override
  String get featureWorkdayFlagHigh => '仕事';

  @override
  String get featureSchoolStressRatingShort => 'ストレス';

  @override
  String get featureScreenUsageRatingShort => '画面';
}
