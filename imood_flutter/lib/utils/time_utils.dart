/// 秒数格式化为 mm:ss 或 hh:mm:ss
class TimeUtils {
  static String formatSeconds(double sec) {
    if (sec <= 0) {
      return '00:00';
    }
    final total = sec.floor();
    final hours = total ~/ 3600; // ~/ 整数除法
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
