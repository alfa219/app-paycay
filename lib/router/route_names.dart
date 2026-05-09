abstract class RouteNames {
  static const splash = '/';
  static const landing = '/landing';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';

  // User shell routes (bottom nav)
  static const userDashboard = '/user/home';
  static const stationMap = '/user/map';
  static const scanStation = '/user/scan';
  static const history = '/user/history';
  static const profile = '/user/profile';

  // Full-screen user routes (no bottom nav)
  static const wallet = '/user/wallet';
  static const topupRequest = '/user/topup';
  static const chargingSession = '/user/charging';
  static const sessionReceipt = '/user/receipt';

  // Admin
  static const admin = '/admin';
}
