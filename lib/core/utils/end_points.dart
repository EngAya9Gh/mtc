class EndPoints {
  static const String baseUrl = 'https://gosample.com/api/';
  static const String debugBaseUrl = 'https://test.gosample.com/api/';

  // Auth
  static const String login = 'driver/login';
  static const String loginWithMobile = 'driver/loginWithMobile';
  static const String profile = 'driver/profile';
  static const String acceptTerms = 'driver/terms/accept';
  static const String getTerms = 'driver/terms/get';

  // Tasks
  static const String tasks = 'driver/tasks';
  static const String startTask = 'driver/task/start';
  static const String confirmTasks = 'driver/tasks/confirm';
  static const String confirmFromLocation = 'driver/task/fromlocation/confirm';
  static const String confirmToLocation = 'driver/task/tolocation/confirm';

  // Samples
  static const String addSamples = 'samples/add';
  static const String addBox = 'samples/box/add';
  static const String listSamples = 'samples/list';
  static const String bagSamples = 'samples/bag';
  static const String bagTypeSamples = 'samples/bag/type';
  static const String addContainer = 'samples/container/add';
  static const String addContainerBags = 'samples/container/bags/add';
  static const String noSamples = 'task/nosamples';

  // Task Status
  static const String collectTask = 'task/collect';
  static const String closeTask = 'task/close';
  static const String closeFreezer = 'task/freezer';
  static const String freezerOut = 'task/freezer/out';
  static const String closeDeliveryTasks = 'tasks/close';
  static const String freezerToOutFreezer = 'tasks/freezer/out';

  // Containers & Bags
  static const String taskContainerBags = 'task/containers/bag';
  static const String containerBags = 'container/bags';
  static const String removeBagFromContainer = 'bag/container/remove';
  static const String taskBags = 'task/bags/get';

  // Location
  static const String checkLocation = 'task/location/check';
  static const String checkTasksLocation = 'tasks/location/check';
  static const String updateLocation = 'driver/location';
  static const String clientTasks = 'driver/client/tasks';

  // Swap
  static const String swapList = 'swap/list/driver';
  static const String rejectSwap = 'swap/reject';
  static const String acceptSwap = 'swap/accept';
  static const String createSwap = 'swap/create';
  static const String receiveSwap = 'swap/receive';
  static const String acceptAllSwap = 'swap/list/driver/accept-all';

  // Money Transfer
  static const String moneyTransferList = 'money/transfer/list';
  static const String verifyFromOtp = 'money/transfer/otp/from/verifiy';
  static const String verifyToOtp = 'money/transfer/otp/to/verifiy';

  // Others
  static const String carImages = 'driver/car/images';
  static const String releaseCar = 'car/release';
  static const String notifications = 'driver/notifications';
  static const String schedule = 'driver-schedule';
  static const String acceptAllSchedule = 'driver/schedule/acceptall';
  static const String emergency = 'emergency';
}
