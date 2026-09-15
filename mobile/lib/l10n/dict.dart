/// Copy for the Sprint 1 authentication module, lifted wholesale from the
/// `DICT` object in `AuthFlow.dc.html`.
///
/// Modelling the dictionary as a class rather than a map means the analyser
/// enforces what the handoff asks for: `en` and `sw` carry identical keys.
enum JhLang { en, sw }

class JhStrings {
  const JhStrings({
    required this.checkingSession,
    required this.createAccount,
    required this.login,
    required this.continueLabel,
    required this.sendOtp,
    required this.sending,
    required this.verifying,
    required this.creating,
    required this.registerTitle,
    required this.loginTitle,
    required this.registerSub,
    required this.registerSubOne,
    required this.oneStepNote,
    required this.loginSub,
    required this.phoneLabel,
    required this.verifyTitle,
    required this.verifySub,
    required this.verify,
    required this.resend,
    required this.resendIn,
    required this.codeExpiresIn,
    required this.codeExpired,
    required this.demoFill,
    required this.haveAccount,
    required this.noAccount,
    required this.register,
    required this.fullName,
    required this.namePlaceholder,
    required this.email,
    required this.greeting,
    required this.sendParcel,
    required this.sendParcelSub,
    required this.track,
    required this.prices,
    required this.support,
    required this.activeDelivery,
    required this.inTransit,
    required this.pickedUp,
    required this.onTheWay,
    required this.delivered,
    required this.eta,
    required this.recent,
    required this.home,
    required this.orders,
    required this.profile,
    required this.account,
    required this.verified,
    required this.changePhone,
    required this.memberSince,
    required this.logout,
    required this.cancel,
    required this.logoutConfirm,
    required this.logoutConfirmSub,
    required this.changePhoneSub,
    required this.currentNumber,
    required this.newNumber,
    required this.errPhone,
    required this.errTaken,
    required this.errTakenCta,
    required this.errUnknown,
    required this.errUnknownCta,
    required this.errSame,
    required this.errOther,
    required this.errOtp,
    required this.errOtpExpired,
    required this.errAttempts,
    required this.errNet,
    required this.errName,
    required this.errEmail,
    required this.errTooMany,
    required this.errSmsFailed,
    required this.errSuspended,
    required this.toastSent,
    required this.toastPhone,
    required this.toastWelcome,
    required this.attemptsLeft,
    required this.legalPrefix,
    required this.legalTerms,
    required this.legalAnd,
    required this.legalPrivacy,
    required this.fastDelivery,
    required this.goodMorning,
    required this.goodAfternoon,
    required this.goodEvening,
    required this.greetingFallback,
    required this.searchHint,
    required this.quickActions,
    required this.shop,
    required this.shopSub,
    required this.trackSub,
    required this.nearby,
    required this.nearbySub,
    required this.favourites,
    required this.favouritesSub,
    required this.recentOrders,
    required this.noOrders,
    required this.noOrdersSub,
    required this.comingSoon,
    required this.activeAccount,
    required this.customerRole,
    required this.accountSettingsSection,
    required this.sessionSection,
    required this.changePhoneRowSub,
    required this.updateEmail,
    required this.updateEmailSub,
    required this.notificationsRow,
    required this.notificationsRowSub,
    required this.helpFaq,
    required this.helpFaqSub,
    required this.privacySecurity,
    required this.privacySecuritySub,
    required this.logoutRowSub,
    required this.deleteAccount,
    required this.deleteAccountSub,
    required this.deleteAccountConfirm,
    required this.deleteAccountConfirmSub,
    required this.deleteAccountWarning,
    required this.deleteAccountCta,
    // --- Sprint 2: Orders ---
    required this.myOrders,
    required this.sendPackageCard,
    required this.sendPackageCardSub,
    required this.ordersActive,
    required this.ordersCompleted,
    required this.ordersCancelled,
    required this.orderPaid,
    required this.orderTapToTrack,
    required this.statusCompleted,
    required this.statusCancelled,
    required this.ordersEmptyActive,
    required this.ordersEmptyActiveSub,
    required this.ordersEmptyCompleted,
    required this.ordersEmptyCompletedSub,
    required this.ordersEmptyCancelled,
    required this.ordersEmptyCancelledSub,
    required this.vehicleMotorcycle,
    required this.vehicleBajaji,
    required this.vehicleVan,
    required this.modeMotoSpec,
    required this.modeBajajiSpec,
    required this.modeCarSpec,
    required this.modeVanSpec,
    required this.modeMotoEta,
    required this.modeBajajiEta,
    required this.modeCarEta,
    required this.modeVanEta,
    required this.kmUnit,
    required this.onboardTitle1,
    required this.onboardSub1,
    required this.onboardTitle2,
    required this.onboardSub2,
    required this.onboardTitle3,
    required this.onboardSub3,
    required this.onboardTitle4,
    required this.onboardSub4,
    required this.payAfterDelivery,
    required this.stepTitleRoute,
    required this.stepTitleDestination,
    required this.stepTitleDelivery,
    required this.stepTitleReview,
    required this.destinationTitle,
    required this.destinationSub,
    required this.destinationSearchHint,
    required this.destinationLandmarkHint,
    required this.destinationConfirm,
    required this.deliveryModeTitle,
    required this.deliveryModeSub,
    required this.modeUnavailable,
    required this.deliveryEstimateTitle,
    required this.estimateFrom,
    required this.estimateTo,
    required this.estimateMode,
    required this.estimateTime,
    required this.estimateFee,
    required this.reviewTitle,
    required this.reviewSub,
    required this.reviewEdit,
    required this.reviewDeliveryPayment,
    required this.reviewPaymentLabel,
    required this.sendPackageButton,
    required this.packageUnitOne,
    required this.packageUnitMany,
    required this.orderCreatedTitle,
    required this.orderCreatedSub,
    required this.deliverySummaryTitle,
    required this.summaryFee,
    required this.summaryPayment,
    required this.findingDriverPill,
    required this.trackPackageButton,
    required this.trackPackageTitle,
    required this.trackFindingDriver,
    required this.trackDriverAssigned,
    required this.trackDriverArriving,
    required this.trackPickedUp,
    required this.trackDelivered,
    required this.trackRequestCreated,
    required this.deliveryTimelineTitle,
    required this.vehicleCar,
    required this.tshPrefix,
    required this.stepWord,
    required this.stepConnector,
    required this.stepTitlePickup,
    required this.stepTitleRecipient,
    required this.stepTitlePackage,
    required this.optionalSuffix,
    required this.pickupTitle,
    required this.pickupSub,
    required this.pickupUseCurrentLocation,
    required this.orderActionFailed,
    required this.pickupLocating,
    required this.pickupSearchHint,
    required this.pickupMoveHint,
    required this.pickupLandmarkLabel,
    required this.pickupLandmarkHint,
    required this.pickupInstructionsLabel,
    required this.pickupInstructionsHint,
    required this.pickupConfirm,
    required this.pickupDenied,
    required this.recipientTitle,
    required this.recipientSub,
    required this.recipientNameLabel,
    required this.recipientNameHint,
    required this.recipientPhoneLabel,
    required this.recipientDeliveryLabel,
    required this.recipientDeliveryHint,
    required this.errRecipientName,
    required this.packageTitle,
    required this.packageSub,
    required this.packageTypeLabel,
    required this.packageSizeLabel,
    required this.quantityLabel,
    required this.packageDescriptionLabel,
    required this.packageDescriptionHint,
    required this.handlingLabel,
    required this.handlingHint,
    required this.pkgDocuments,
    required this.pkgClothes,
    required this.pkgFood,
    required this.pkgElectronics,
    required this.pkgHousehold,
    required this.pkgOther,
    required this.sizeSmall,
    required this.sizeSmallSub,
    required this.sizeMedium,
    required this.sizeMediumSub,
    required this.sizeLarge,
    required this.sizeLargeSub,
    required this.declarationTitle,
    required this.declarationBody,
    required this.declarationAgree,
    required this.errDeclaration,
    required this.orderDetailTitle,
    required this.trackingTitle,
    required this.trackingPlaceholder,
    required this.orderRouteLabel,
    required this.orderRecipientLabel,
    required this.orderPackageLabel,
    required this.orderPriceLabel,
    required this.orderPlacedLabel,
    required this.orderPickupLabel,
    required this.orderPlacedToast,
    required this.cancelOrderTitle,
    required this.cancelOrderBody,
    required this.cancelOrderCta,
    required this.cancelOrderConfirm,
    required this.keepOrder,
    required this.orderCancelledToast,
    required this.contactSupport,
    required this.backToHome,
    required this.proofOfDeliveryTitle,
    required this.receivedByLabel,
    required this.rateDriverTitle,
    required this.rateDriverSub,
    required this.youRatedThisDelivery,
    required this.rateThisDelivery,
    required this.reorder,
    required this.deliveryDetailsTitle,
    required this.deliveryNoteLabel,
    required this.recentPlacesTitle,
    required this.attachPhotoLabel,
    required this.attachPhotoHint,
    required this.takePhoto,
    required this.chooseFromGallery,
    required this.removePhotoLabel,
  });

  final String checkingSession;
  final String createAccount;
  final String login;
  final String continueLabel;
  final String sendOtp;
  final String sending;
  final String verifying;
  final String creating;
  final String registerTitle;
  final String loginTitle;
  final String registerSub;
  final String registerSubOne;
  final String oneStepNote;
  final String loginSub;
  final String phoneLabel;
  final String verifyTitle;
  final String verifySub;
  final String verify;
  final String resend;
  final String resendIn;
  final String codeExpiresIn;
  final String codeExpired;
  final String demoFill;
  final String haveAccount;
  final String noAccount;
  final String register;
  final String fullName;
  final String namePlaceholder;
  final String email;
  final String greeting;
  final String sendParcel;
  final String sendParcelSub;
  final String track;
  final String prices;
  final String support;
  final String activeDelivery;
  final String inTransit;
  final String pickedUp;
  final String onTheWay;
  final String delivered;
  final String eta;
  final String recent;
  final String home;
  final String orders;
  final String profile;
  final String account;
  final String verified;
  final String changePhone;
  final String memberSince;
  final String logout;
  final String cancel;
  final String logoutConfirm;
  final String logoutConfirmSub;
  final String changePhoneSub;
  final String currentNumber;
  final String newNumber;
  final String errPhone;
  final String errTaken;
  final String errTakenCta;
  final String errUnknown;
  final String errUnknownCta;
  final String errSame;
  final String errOther;
  final String errOtp;
  final String errOtpExpired;
  final String errAttempts;
  final String errNet;
  final String errName;
  final String errEmail;
  final String errTooMany;
  final String errSmsFailed;
  final String errSuspended;
  final String toastSent;
  final String toastPhone;
  final String toastWelcome;
  final String attemptsLeft;
  final String legalPrefix;
  final String legalTerms;
  final String legalAnd;
  final String legalPrivacy;
  final String fastDelivery;
  final String goodMorning;
  final String goodAfternoon;
  final String goodEvening;
  final String greetingFallback;
  final String searchHint;
  final String quickActions;
  final String shop;
  final String shopSub;
  final String trackSub;
  final String nearby;
  final String nearbySub;
  final String favourites;
  final String favouritesSub;
  final String recentOrders;
  final String noOrders;
  final String noOrdersSub;
  final String comingSoon;
  final String activeAccount;
  final String customerRole;
  final String accountSettingsSection;
  final String sessionSection;
  final String changePhoneRowSub;
  final String updateEmail;
  final String updateEmailSub;
  final String notificationsRow;
  final String notificationsRowSub;
  final String helpFaq;
  final String helpFaqSub;
  final String privacySecurity;
  final String privacySecuritySub;
  final String logoutRowSub;
  final String deleteAccount;
  final String deleteAccountSub;
  final String deleteAccountConfirm;
  final String deleteAccountConfirmSub;
  final String deleteAccountWarning;
  final String deleteAccountCta;

  // --- Sprint 2: Orders ---
  final String myOrders;
  final String sendPackageCard;
  final String sendPackageCardSub;
  final String ordersActive;
  final String ordersCompleted;
  final String ordersCancelled;
  final String orderPaid;
  final String orderTapToTrack;
  final String statusCompleted;
  final String statusCancelled;
  final String ordersEmptyActive;
  final String ordersEmptyActiveSub;
  final String ordersEmptyCompleted;
  final String ordersEmptyCompletedSub;
  final String ordersEmptyCancelled;
  final String ordersEmptyCancelledSub;
  final String vehicleMotorcycle;
  final String vehicleBajaji;
  final String vehicleVan;
  final String modeMotoSpec;
  final String modeBajajiSpec;
  final String modeCarSpec;
  final String modeVanSpec;
  final String modeMotoEta;
  final String modeBajajiEta;
  final String modeCarEta;
  final String modeVanEta;
  final String kmUnit;
  final String onboardTitle1;
  final String onboardSub1;
  final String onboardTitle2;
  final String onboardSub2;
  final String onboardTitle3;
  final String onboardSub3;
  final String onboardTitle4;
  final String onboardSub4;
  final String payAfterDelivery;
  final String stepTitleRoute;
  final String stepTitleDestination;
  final String stepTitleDelivery;
  final String stepTitleReview;
  final String destinationTitle;
  final String destinationSub;
  final String destinationSearchHint;
  final String destinationLandmarkHint;
  final String destinationConfirm;
  final String deliveryModeTitle;
  final String deliveryModeSub;
  final String modeUnavailable;
  final String deliveryEstimateTitle;
  final String estimateFrom;
  final String estimateTo;
  final String estimateMode;
  final String estimateTime;
  final String estimateFee;
  final String reviewTitle;
  final String reviewSub;
  final String reviewEdit;
  final String reviewDeliveryPayment;
  final String reviewPaymentLabel;
  final String sendPackageButton;
  final String packageUnitOne;
  final String packageUnitMany;
  final String orderCreatedTitle;
  final String orderCreatedSub;
  final String deliverySummaryTitle;
  final String summaryFee;
  final String summaryPayment;
  final String findingDriverPill;
  final String trackPackageButton;
  final String trackPackageTitle;
  final String trackFindingDriver;
  final String trackDriverAssigned;
  final String trackDriverArriving;
  final String trackPickedUp;
  final String trackDelivered;
  final String trackRequestCreated;
  final String deliveryTimelineTitle;
  final String vehicleCar;
  final String tshPrefix;
  final String stepWord;
  final String stepConnector;
  final String stepTitlePickup;
  final String stepTitleRecipient;
  final String stepTitlePackage;
  final String optionalSuffix;
  final String pickupTitle;
  final String pickupSub;
  final String pickupUseCurrentLocation;
  final String orderActionFailed;
  final String pickupLocating;
  final String pickupSearchHint;
  final String pickupMoveHint;
  final String pickupLandmarkLabel;
  final String pickupLandmarkHint;
  final String pickupInstructionsLabel;
  final String pickupInstructionsHint;
  final String pickupConfirm;
  final String pickupDenied;
  final String recipientTitle;
  final String recipientSub;
  final String recipientNameLabel;
  final String recipientNameHint;
  final String recipientPhoneLabel;
  final String recipientDeliveryLabel;
  final String recipientDeliveryHint;
  final String errRecipientName;
  final String packageTitle;
  final String packageSub;
  final String packageTypeLabel;
  final String packageSizeLabel;
  final String quantityLabel;
  final String packageDescriptionLabel;
  final String packageDescriptionHint;
  final String handlingLabel;
  final String handlingHint;
  final String pkgDocuments;
  final String pkgClothes;
  final String pkgFood;
  final String pkgElectronics;
  final String pkgHousehold;
  final String pkgOther;
  final String sizeSmall;
  final String sizeSmallSub;
  final String sizeMedium;
  final String sizeMediumSub;
  final String sizeLarge;
  final String sizeLargeSub;
  final String declarationTitle;
  final String declarationBody;
  final String declarationAgree;
  final String errDeclaration;
  final String orderDetailTitle;
  final String trackingTitle;
  final String trackingPlaceholder;
  final String orderRouteLabel;
  final String orderRecipientLabel;
  final String orderPackageLabel;
  final String orderPriceLabel;
  final String orderPlacedLabel;
  final String orderPickupLabel;
  final String orderPlacedToast;
  final String cancelOrderTitle;
  final String cancelOrderBody;
  final String cancelOrderCta;
  final String cancelOrderConfirm;
  final String keepOrder;
  final String orderCancelledToast;
  final String contactSupport;
  final String backToHome;
  final String proofOfDeliveryTitle;
  final String receivedByLabel;
  final String rateDriverTitle;
  final String rateDriverSub;
  final String youRatedThisDelivery;
  final String rateThisDelivery;
  final String reorder;
  final String deliveryDetailsTitle;
  final String deliveryNoteLabel;
  final String recentPlacesTitle;
  final String attachPhotoLabel;
  final String attachPhotoHint;
  final String takePhoto;
  final String chooseFromGallery;
  final String removePhotoLabel;

  static const JhStrings en = JhStrings(
    checkingSession: 'Checking your session',
    createAccount: 'Create account',
    login: 'Log in',
    continueLabel: 'Continue',
    sendOtp: 'Send code',
    sending: 'Sending code…',
    verifying: 'Verifying…',
    creating: 'Creating account…',
    registerTitle: 'Create your account',
    loginTitle: 'Welcome back',
    registerSub: 'Enter your phone number. We will send a verification code by SMS.',
    registerSubOne:
        'Fill in your details once. We will send a verification code to the number you enter.',
    oneStepNote:
        'On submit we send a 6-digit code by SMS. Your account is created once the code is verified.',
    loginSub: 'Log in with the phone number registered on your account.',
    phoneLabel: 'Phone number',
    verifyTitle: 'Verify your phone',
    verifySub: 'Enter the 6-digit code sent to',
    verify: 'Verify',
    resend: 'Resend code',
    resendIn: 'Resend in',
    codeExpiresIn: 'Code expires in',
    codeExpired: 'Code expired',
    demoFill: 'demo: tap to fill 123456',
    haveAccount: 'Already have an account?',
    noAccount: 'Don’t have an account?',
    register: 'Register',
    fullName: 'Full name',
    namePlaceholder: 'Amina Hassan',
    email: 'Email address',
    greeting: 'Habari',
    sendParcel: 'Send a parcel',
    sendParcelSub: 'Pickup in 15 min around you',
    track: 'Track',
    prices: 'Prices',
    support: 'Support',
    activeDelivery: 'Active delivery',
    inTransit: 'In transit',
    pickedUp: 'Picked up',
    onTheWay: 'On the way',
    delivered: 'Delivered',
    eta: 'Arriving in',
    recent: 'Recent deliveries',
    home: 'Home',
    orders: 'Orders',
    profile: 'Profile',
    account: 'Account',
    verified: 'Verified',
    changePhone: 'Change phone number',
    memberSince: 'Member since',
    logout: 'Log out',
    cancel: 'Cancel',
    logoutConfirm: 'Log out?',
    logoutConfirmSub: 'Are you sure you want to log out of your Jihudumie account?',
    changePhoneSub:
        'Your new number becomes your login identifier. We verify it before anything changes.',
    currentNumber: 'Current number',
    newNumber: 'New number',
    errPhone: 'Please enter a valid Tanzanian phone number.',
    errTaken: 'This phone number is already registered.',
    errTakenCta: 'Log in instead',
    errUnknown: 'This phone number is not registered.',
    errUnknownCta: 'Create an account',
    errSame: 'This is already your registered number.',
    errOther: 'This phone number is associated with another Jihudumie account.',
    errOtp: 'The verification code is incorrect. Please try again.',
    errOtpExpired: 'This verification code has expired. Please request a new code.',
    errAttempts: 'Too many verification attempts. Request a new code and try again.',
    errNet: 'Unable to connect to Jihudumie. Check your internet connection and try again.',
    errName: 'Please enter your full name.',
    errEmail: 'Please enter a valid email address.',
    errTooMany: 'Too many attempts. Please wait a moment and try again.',
    errSmsFailed: 'We could not send the verification code. Please try again.',
    errSuspended: 'This account is not active. Please contact support.',
    toastSent: 'A verification code has been sent to your phone.',
    toastPhone: 'Phone number updated. Use it to log in next time.',
    toastWelcome: 'Account created. Welcome to Jihudumie.',
    attemptsLeft: 'attempts left',
    legalPrefix: 'By continuing you agree to our',
    legalTerms: 'Terms of Service',
    legalAnd: '&',
    legalPrivacy: 'Privacy Policy',
    fastDelivery: 'Fast delivery',
    goodMorning: 'Good morning',
    goodAfternoon: 'Good afternoon',
    goodEvening: 'Good evening',
    greetingFallback: 'there',
    searchHint: 'Search vendors, products...',
    quickActions: 'Quick Actions',
    shop: 'Shop',
    shopSub: 'Browse vendors',
    trackSub: 'Your orders',
    nearby: 'Nearby',
    nearbySub: 'Vendors near you',
    favourites: 'Favorites',
    favouritesSub: 'Saved stores',
    recentOrders: 'Recent Orders',
    noOrders: 'No orders yet',
    noOrdersSub: 'Start browsing to place your first order',
    comingSoon: 'Coming in Sprint 2',
    activeAccount: 'Active account',
    customerRole: 'Customer',
    accountSettingsSection: 'Account settings',
    sessionSection: 'Session',
    changePhoneRowSub: 'Update your registered phone',
    updateEmail: 'Update email address',
    updateEmailSub: 'Add or change your email',
    notificationsRow: 'Notifications',
    notificationsRowSub: 'Manage your alerts',
    helpFaq: 'Help & FAQ',
    helpFaqSub: 'Get help with your account',
    privacySecurity: 'Privacy & Security',
    privacySecuritySub: 'Control your data',
    logoutRowSub: 'Sign out of your account',
    deleteAccount: 'Delete account',
    deleteAccountSub: 'Permanently remove your data',
    deleteAccountConfirm: 'Delete account?',
    deleteAccountConfirmSub:
        'This will permanently delete your Jihudumie account and all associated data.',
    deleteAccountWarning: 'This action cannot be undone.',
    deleteAccountCta: 'Yes, delete my account',
    myOrders: 'My Orders',
    sendPackageCard: 'Send a Package',
    sendPackageCardSub: 'Send safely from one location to another',
    ordersActive: 'Active',
    ordersCompleted: 'Completed',
    ordersCancelled: 'Cancelled',
    orderPaid: 'Paid',
    orderTapToTrack: 'In transit · Tap to track',
    statusCompleted: 'Completed',
    statusCancelled: 'Cancelled',
    ordersEmptyActive: 'No active orders',
    ordersEmptyActiveSub: 'Your ongoing deliveries will appear here',
    ordersEmptyCompleted: 'No completed orders yet',
    ordersEmptyCompletedSub: 'Delivered parcels will be listed here',
    ordersEmptyCancelled: 'No cancelled orders',
    ordersEmptyCancelledSub: 'Cancelled deliveries will show here',
    vehicleMotorcycle: 'Motorcycle',
    vehicleBajaji: 'Bajaji',
    vehicleVan: 'Lorry',
    modeMotoSpec: 'Small packages · Up to 5 kg',
    modeBajajiSpec: 'Medium packages · Up to 15 kg',
    modeCarSpec: 'Larger packages · Up to 30 kg',
    modeVanSpec: 'Bulky items · Up to 200 kg',
    modeMotoEta: '~45 min',
    modeBajajiEta: '~50 min',
    modeCarEta: '~35 min',
    modeVanEta: '~60 min',
    kmUnit: 'km',
    onboardTitle1: 'Send it your way',
    onboardSub1: 'Pick a boda, bajaji, car or lorry — whatever fits your package.',
    onboardTitle2: 'Trusted drivers',
    onboardSub2: 'Every delivery is carried by a verified, accountable courier.',
    onboardTitle3: 'Pay after delivery',
    onboardSub3: 'Settle up once your package arrives — not before.',
    onboardTitle4: 'Nationwide reach',
    onboardSub4: 'From Dar es Salaam to anywhere in Tanzania, door to door.',
    payAfterDelivery: 'Pay after delivery',
    stepTitleRoute: 'Route',
    stepTitleDestination: 'Destination',
    stepTitleDelivery: 'Delivery',
    stepTitleReview: 'Review',
    destinationTitle: 'Destination',
    destinationSub: 'Where should the package go?',
    destinationSearchHint: 'Search destination…',
    destinationLandmarkHint: 'e.g. Near ABC Petrol Station',
    destinationConfirm: 'Confirm Destination',
    deliveryModeTitle: 'Choose Delivery Mode',
    deliveryModeSub: 'Select how your package will be transported.',
    modeUnavailable: 'Unavailable',
    deliveryEstimateTitle: 'Delivery estimate',
    estimateFrom: 'From',
    estimateTo: 'To',
    estimateMode: 'Mode',
    estimateTime: 'Estimated time',
    estimateFee: 'Delivery fee',
    reviewTitle: 'Review Delivery',
    reviewSub: 'Check everything before sending.',
    reviewEdit: 'Edit',
    reviewDeliveryPayment: 'Delivery & Payment',
    reviewPaymentLabel: 'Payment',
    sendPackageButton: 'Send Package',
    packageUnitOne: 'package',
    packageUnitMany: 'packages',
    orderCreatedTitle: 'Package Request Created',
    orderCreatedSub: 'Your delivery request has been created successfully.',
    deliverySummaryTitle: 'Delivery summary',
    summaryFee: 'Fee',
    summaryPayment: 'Payment',
    findingDriverPill: 'Finding a driver…',
    trackPackageButton: 'Track Package',
    trackPackageTitle: 'Track Package',
    trackFindingDriver: 'Finding a driver…',
    trackDriverAssigned: 'Driver assigned',
    trackDriverArriving: 'Driver arriving',
    trackPickedUp: 'Package picked up',
    trackDelivered: 'Delivered',
    trackRequestCreated: 'Request created',
    deliveryTimelineTitle: 'Delivery timeline',
    vehicleCar: 'Car',
    tshPrefix: 'TSh',
    stepWord: 'Step',
    stepConnector: 'of',
    stepTitlePickup: 'Pickup',
    stepTitleRecipient: 'Recipient',
    stepTitlePackage: 'Package',
    optionalSuffix: 'optional',
    pickupTitle: 'Pickup location',
    pickupSub: 'Where should we collect the package?',
    pickupUseCurrentLocation: 'Use Current Location',
    orderActionFailed: 'Something went wrong. Please try again.',
    pickupLocating: 'Finding your location…',
    pickupSearchHint: 'Search location…',
    pickupMoveHint: 'Move map to adjust pin',
    pickupLandmarkLabel: 'Landmark',
    pickupLandmarkHint: 'e.g. Near XYZ Shop',
    pickupInstructionsLabel: 'Pickup instructions',
    pickupInstructionsHint: 'e.g. Call me when you arrive',
    pickupConfirm: 'Confirm Location',
    pickupDenied:
        'Location access is off. Choose your pickup point on the map instead.',
    recipientTitle: 'Recipient Details',
    recipientSub: 'Who will receive the package?',
    recipientNameLabel: 'Recipient Name',
    recipientNameHint: 'e.g. John Michael',
    recipientPhoneLabel: 'Phone Number',
    recipientDeliveryLabel: 'Delivery instructions',
    recipientDeliveryHint: 'e.g. Call before delivering',
    errRecipientName: 'Please enter the recipient’s name.',
    packageTitle: 'Package Details',
    packageSub: 'Tell us what you’re sending.',
    packageTypeLabel: 'Package type',
    packageSizeLabel: 'Package size',
    quantityLabel: 'Quantity',
    packageDescriptionLabel: 'Package description',
    packageDescriptionHint: 'Briefly describe your package',
    handlingLabel: 'Handling instructions',
    handlingHint: 'e.g. Fragile, handle with care',
    pkgDocuments: 'Documents',
    pkgClothes: 'Clothes',
    pkgFood: 'Food',
    pkgElectronics: 'Electronics',
    pkgHousehold: 'Household Item',
    pkgOther: 'Other',
    sizeSmall: 'Small',
    sizeSmallSub: 'Fits in a backpack',
    sizeMedium: 'Medium',
    sizeMediumSub: 'Fits in a suitcase',
    sizeLarge: 'Large',
    sizeLargeSub: 'Oversized item',
    declarationTitle: 'Package Declaration',
    declarationBody:
        'I confirm that this package does not contain prohibited or restricted items.',
    declarationAgree: 'I agree to the package declaration',
    errDeclaration: 'Please agree to the package declaration to continue.',
    orderDetailTitle: 'Order Details',
    trackingTitle: 'Tracking',
    trackingPlaceholder:
        'Live tracking will be available once a driver is assigned.',
    orderRouteLabel: 'Route',
    orderRecipientLabel: 'Recipient',
    orderPackageLabel: 'Package',
    orderPriceLabel: 'Price',
    orderPlacedLabel: 'Placed',
    orderPickupLabel: 'Pickup',
    orderPlacedToast: 'Order placed. We are finding you a driver.',
    cancelOrderTitle: 'Cancel this delivery?',
    cancelOrderBody:
        'The courier hasn’t picked up your package yet. This can’t be undone.',
    cancelOrderCta: 'Cancel Order',
    cancelOrderConfirm: 'Yes, Cancel',
    keepOrder: 'Keep Order',
    orderCancelledToast: 'Order cancelled',
    contactSupport: 'Contact Support',
    backToHome: 'Back to Home',
    proofOfDeliveryTitle: 'Proof of Delivery',
    receivedByLabel: 'Received by',
    rateDriverTitle: 'Rate your driver',
    rateDriverSub: 'How was your delivery experience?',
    youRatedThisDelivery: 'You rated this delivery',
    rateThisDelivery: 'Rate this delivery',
    reorder: 'Reorder',
    deliveryDetailsTitle: 'Delivery Details',
    deliveryNoteLabel: 'Note',
    recentPlacesTitle: 'Recent Places',
    attachPhotoLabel: 'Photo of the package',
    attachPhotoHint:
        'Add a photo so the courier can confirm what they’re picking up.',
    takePhoto: 'Take Photo',
    chooseFromGallery: 'Choose from Gallery',
    removePhotoLabel: 'Remove photo',
  );

  static const JhStrings sw = JhStrings(
    checkingSession: 'Tunaangalia kipindi chako',
    createAccount: 'Fungua akaunti',
    login: 'Ingia',
    continueLabel: 'Endelea',
    sendOtp: 'Tuma namba',
    sending: 'Tunatuma namba…',
    verifying: 'Tunathibitisha…',
    creating: 'Tunafungua akaunti…',
    registerTitle: 'Fungua akaunti yako',
    loginTitle: 'Karibu tena',
    registerSub: 'Weka namba yako ya simu. Tutakutumia namba ya uthibitisho kwa SMS.',
    registerSubOne:
        'Jaza taarifa zako mara moja. Tutatuma namba ya uthibitisho kwenye simu uliyoweka.',
    oneStepNote:
        'Tutatuma namba ya tarakimu 6 kwa SMS. Akaunti yako inafunguliwa baada ya uthibitisho.',
    loginSub: 'Ingia kwa namba ya simu iliyosajiliwa kwenye akaunti yako.',
    phoneLabel: 'Namba ya simu',
    verifyTitle: 'Thibitisha simu yako',
    verifySub: 'Weka namba 6 tulizotuma kwa',
    verify: 'Thibitisha',
    resend: 'Tuma tena',
    resendIn: 'Tuma tena baada ya',
    codeExpiresIn: 'Namba inaisha baada ya',
    codeExpired: 'Namba imeisha',
    demoFill: 'onyesho: bonyeza kuweka 123456',
    haveAccount: 'Una akaunti tayari?',
    noAccount: 'Hauna akaunti?',
    register: 'Jisajili',
    fullName: 'Jina kamili',
    namePlaceholder: 'Amina Hassan',
    email: 'Barua pepe',
    greeting: 'Habari',
    sendParcel: 'Tuma kifurushi',
    sendParcelSub: 'Kuchukuliwa dakika 15 karibu nawe',
    track: 'Fuatilia',
    prices: 'Bei',
    support: 'Msaada',
    activeDelivery: 'Usafirishaji unaoendelea',
    inTransit: 'Njiani',
    pickedUp: 'Imechukuliwa',
    onTheWay: 'Njiani',
    delivered: 'Imefika',
    eta: 'Inafika baada ya',
    recent: 'Usafirishaji wa hivi karibuni',
    home: 'Nyumbani',
    orders: 'Oda',
    profile: 'Wasifu',
    account: 'Akaunti',
    verified: 'Imethibitishwa',
    changePhone: 'Badilisha namba ya simu',
    memberSince: 'Mwanachama kuanzia',
    logout: 'Toka',
    cancel: 'Ghairi',
    logoutConfirm: 'Toka kwenye akaunti?',
    logoutConfirmSub: 'Una uhakika unataka kutoka kwenye akaunti yako ya Jihudumie?',
    changePhoneSub:
        'Namba mpya itakuwa kitambulisho chako cha kuingia. Tunaithibitisha kwanza.',
    currentNumber: 'Namba ya sasa',
    newNumber: 'Namba mpya',
    errPhone: 'Tafadhali weka namba sahihi ya simu ya Tanzania.',
    errTaken: 'Namba hii ya simu imesajiliwa tayari.',
    errTakenCta: 'Ingia badala yake',
    errUnknown: 'Namba hii ya simu haijasajiliwa.',
    errUnknownCta: 'Fungua akaunti',
    errSame: 'Hii ni namba yako iliyosajiliwa tayari.',
    errOther: 'Namba hii inatumika kwenye akaunti nyingine ya Jihudumie.',
    errOtp: 'Namba ya uthibitisho si sahihi. Jaribu tena.',
    errOtpExpired: 'Namba hii ya uthibitisho imeisha. Omba namba mpya.',
    errAttempts: 'Majaribio mengi mno. Omba namba mpya na ujaribu tena.',
    errNet: 'Imeshindikana kuunganisha na Jihudumie. Angalia intaneti yako na ujaribu tena.',
    errName: 'Tafadhali weka jina lako kamili.',
    errEmail: 'Tafadhali weka barua pepe sahihi.',
    errTooMany: 'Majaribio mengi mno. Tafadhali subiri kidogo kisha ujaribu tena.',
    errSmsFailed: 'Imeshindikana kutuma namba ya uthibitisho. Tafadhali jaribu tena.',
    errSuspended: 'Akaunti hii haifanyi kazi. Tafadhali wasiliana na huduma kwa wateja.',
    toastSent: 'Namba ya uthibitisho imetumwa kwenye simu yako.',
    toastPhone: 'Namba ya simu imebadilishwa. Itumie kuingia mara ijayo.',
    toastWelcome: 'Akaunti imefunguliwa. Karibu Jihudumie.',
    attemptsLeft: 'majaribio yaliyosalia',
    legalPrefix: 'Kwa kuendelea unakubali',
    legalTerms: 'Masharti ya Huduma',
    legalAnd: 'na',
    legalPrivacy: 'Sera ya Faragha',
    fastDelivery: 'Usafirishaji wa haraka',
    goodMorning: 'Habari za asubuhi',
    goodAfternoon: 'Habari za mchana',
    goodEvening: 'Habari za jioni',
    greetingFallback: 'rafiki',
    searchHint: 'Tafuta wauzaji, bidhaa...',
    quickActions: 'Vitendo vya haraka',
    shop: 'Duka',
    shopSub: 'Vinjari wauzaji',
    trackSub: 'Oda zako',
    nearby: 'Karibu nawe',
    nearbySub: 'Wauzaji walio karibu',
    favourites: 'Vipendwa',
    favouritesSub: 'Maduka uliyohifadhi',
    recentOrders: 'Oda za hivi karibuni',
    noOrders: 'Bado hakuna oda',
    noOrdersSub: 'Anza kuvinjari ili kuweka oda yako ya kwanza',
    comingSoon: 'Inakuja katika Sprint 2',
    activeAccount: 'Akaunti inatumika',
    customerRole: 'Mteja',
    accountSettingsSection: 'Mipangilio ya akaunti',
    sessionSection: 'Kipindi',
    changePhoneRowSub: 'Sasisha namba yako iliyosajiliwa',
    updateEmail: 'Sasisha barua pepe',
    updateEmailSub: 'Ongeza au badilisha barua pepe yako',
    notificationsRow: 'Arifa',
    notificationsRowSub: 'Simamia arifa zako',
    helpFaq: 'Msaada na Maswali',
    helpFaqSub: 'Pata msaada kuhusu akaunti yako',
    privacySecurity: 'Faragha na Usalama',
    privacySecuritySub: 'Dhibiti taarifa zako',
    logoutRowSub: 'Toka kwenye akaunti yako',
    deleteAccount: 'Futa akaunti',
    deleteAccountSub: 'Ondoa kabisa taarifa zako',
    deleteAccountConfirm: 'Futa akaunti?',
    deleteAccountConfirmSub:
        'Hatua hii itafuta kabisa akaunti yako ya Jihudumie na taarifa zote zinazohusiana.',
    deleteAccountWarning: 'Hatua hii haiwezi kutenduliwa.',
    deleteAccountCta: 'Ndiyo, futa akaunti yangu',
    myOrders: 'Oda Zangu',
    sendPackageCard: 'Tuma Kifurushi',
    sendPackageCardSub: 'Tuma kwa usalama kutoka sehemu moja hadi nyingine',
    ordersActive: 'Zinaendelea',
    ordersCompleted: 'Zimekamilika',
    ordersCancelled: 'Zilizoghairiwa',
    orderPaid: 'Imelipwa',
    orderTapToTrack: 'Njiani · Gusa kufuatilia',
    statusCompleted: 'Imekamilika',
    statusCancelled: 'Imeghairiwa',
    ordersEmptyActive: 'Hakuna oda zinazoendelea',
    ordersEmptyActiveSub: 'Usafirishaji unaoendelea utaonekana hapa',
    ordersEmptyCompleted: 'Bado hakuna oda zilizokamilika',
    ordersEmptyCompletedSub: 'Vifurushi vilivyofikishwa vitaorodheshwa hapa',
    ordersEmptyCancelled: 'Hakuna oda zilizoghairiwa',
    ordersEmptyCancelledSub: 'Usafirishaji ulioghairiwa utaonekana hapa',
    vehicleMotorcycle: 'Pikipiki',
    vehicleBajaji: 'Bajaji',
    vehicleVan: 'Lori',
    modeMotoSpec: 'Vifurushi vidogo · Hadi kg 5',
    modeBajajiSpec: 'Vifurushi vya kati · Hadi kg 15',
    modeCarSpec: 'Vifurushi vikubwa · Hadi kg 30',
    modeVanSpec: 'Vitu vikubwa · Hadi kg 200',
    modeMotoEta: '~dakika 45',
    modeBajajiEta: '~dakika 50',
    modeCarEta: '~dakika 35',
    modeVanEta: '~dakika 60',
    kmUnit: 'km',
    onboardTitle1: 'Tuma jinsi unavyotaka',
    onboardSub1: 'Chagua boda, bajaji, gari au lori — chochote kinachofaa mzigo wako.',
    onboardTitle2: 'Madereva wanaoaminika',
    onboardSub2: 'Kila usafirishaji unafanywa na dereva aliyethibitishwa na anayewajibika.',
    onboardTitle3: 'Lipa baada ya kupokea',
    onboardSub3: 'Malipo yanafanyika mzigo ukishafika — si kabla.',
    onboardTitle4: 'Tunafika kila mahali',
    onboardSub4: 'Kutoka Dar es Salaam hadi popote Tanzania, hadi mlangoni.',
    payAfterDelivery: 'Lipa baada ya kufikishwa',
    stepTitleRoute: 'Njia',
    stepTitleDestination: 'Kufikisha',
    stepTitleDelivery: 'Usafirishaji',
    stepTitleReview: 'Kagua',
    destinationTitle: 'Mahali pa kufikisha',
    destinationSub: 'Kifurushi kiende wapi?',
    destinationSearchHint: 'Tafuta mahali pa kufikisha…',
    destinationLandmarkHint: 'mf. Karibu na Kituo cha Mafuta cha ABC',
    destinationConfirm: 'Thibitisha Mahali',
    deliveryModeTitle: 'Chagua Njia ya Usafirishaji',
    deliveryModeSub: 'Chagua jinsi kifurushi chako kitakavyosafirishwa.',
    modeUnavailable: 'Haipatikani',
    deliveryEstimateTitle: 'Makadirio ya usafirishaji',
    estimateFrom: 'Kutoka',
    estimateTo: 'Kwenda',
    estimateMode: 'Njia',
    estimateTime: 'Muda wa makadirio',
    estimateFee: 'Ada ya usafirishaji',
    reviewTitle: 'Kagua Usafirishaji',
    reviewSub: 'Hakiki kila kitu kabla ya kutuma.',
    reviewEdit: 'Hariri',
    reviewDeliveryPayment: 'Usafirishaji na Malipo',
    reviewPaymentLabel: 'Malipo',
    sendPackageButton: 'Tuma Kifurushi',
    packageUnitOne: 'kifurushi',
    packageUnitMany: 'vifurushi',
    orderCreatedTitle: 'Ombi la Kifurushi Limeundwa',
    orderCreatedSub: 'Ombi lako la usafirishaji limeundwa kwa mafanikio.',
    deliverySummaryTitle: 'Muhtasari wa usafirishaji',
    summaryFee: 'Ada',
    summaryPayment: 'Malipo',
    findingDriverPill: 'Tunatafuta dereva…',
    trackPackageButton: 'Fuatilia Kifurushi',
    trackPackageTitle: 'Fuatilia Kifurushi',
    trackFindingDriver: 'Tunatafuta dereva…',
    trackDriverAssigned: 'Dereva amepangwa',
    trackDriverArriving: 'Dereva anakuja',
    trackPickedUp: 'Kifurushi kimechukuliwa',
    trackDelivered: 'Kimefikishwa',
    trackRequestCreated: 'Ombi limeundwa',
    deliveryTimelineTitle: 'Ratiba ya usafirishaji',
    vehicleCar: 'Gari',
    tshPrefix: 'TSh',
    stepWord: 'Hatua',
    stepConnector: 'kati ya',
    stepTitlePickup: 'Kuchukua',
    stepTitleRecipient: 'Mpokeaji',
    stepTitlePackage: 'Kifurushi',
    optionalSuffix: 'si lazima',
    pickupTitle: 'Mahali pa kuchukua',
    pickupSub: 'Tuchukue kifurushi wapi?',
    pickupUseCurrentLocation: 'Tumia Mahali Nilipo',
    orderActionFailed: 'Hitilafu imetokea. Tafadhali jaribu tena.',
    pickupLocating: 'Tunatafuta mahali ulipo…',
    pickupSearchHint: 'Tafuta mahali…',
    pickupMoveHint: 'Sogeza ramani kurekebisha alama',
    pickupLandmarkLabel: 'Alama ya eneo',
    pickupLandmarkHint: 'mf. Karibu na Duka la XYZ',
    pickupInstructionsLabel: 'Maelekezo ya kuchukua',
    pickupInstructionsHint: 'mf. Nipigie ukifika',
    pickupConfirm: 'Thibitisha Mahali',
    pickupDenied:
        'Ufikiaji wa mahali umezimwa. Chagua mahali pa kuchukua kwenye ramani.',
    recipientTitle: 'Taarifa za Mpokeaji',
    recipientSub: 'Nani atapokea kifurushi?',
    recipientNameLabel: 'Jina la Mpokeaji',
    recipientNameHint: 'mf. John Michael',
    recipientPhoneLabel: 'Namba ya Simu',
    recipientDeliveryLabel: 'Maelekezo ya kufikisha',
    recipientDeliveryHint: 'mf. Piga simu kabla ya kufikisha',
    errRecipientName: 'Tafadhali weka jina la mpokeaji.',
    packageTitle: 'Taarifa za Kifurushi',
    packageSub: 'Tuambie unachotuma.',
    packageTypeLabel: 'Aina ya kifurushi',
    packageSizeLabel: 'Ukubwa wa kifurushi',
    quantityLabel: 'Idadi',
    packageDescriptionLabel: 'Maelezo ya kifurushi',
    packageDescriptionHint: 'Eleza kwa ufupi kifurushi chako',
    handlingLabel: 'Maelekezo ya utunzaji',
    handlingHint: 'mf. Dhaifu, shika kwa uangalifu',
    pkgDocuments: 'Nyaraka',
    pkgClothes: 'Nguo',
    pkgFood: 'Chakula',
    pkgElectronics: 'Elektroniki',
    pkgHousehold: 'Kifaa cha Nyumbani',
    pkgOther: 'Nyingine',
    sizeSmall: 'Ndogo',
    sizeSmallSub: 'Inaingia kwenye mkoba',
    sizeMedium: 'Wastani',
    sizeMediumSub: 'Inaingia kwenye sanduku',
    sizeLarge: 'Kubwa',
    sizeLargeSub: 'Kifaa kikubwa kupita kiasi',
    declarationTitle: 'Tamko la Kifurushi',
    declarationBody:
        'Nathibitisha kuwa kifurushi hiki hakina vitu vilivyopigwa marufuku au vyenye vikwazo.',
    declarationAgree: 'Nakubaliana na tamko la kifurushi',
    errDeclaration: 'Tafadhali kubali tamko la kifurushi ili kuendelea.',
    orderDetailTitle: 'Taarifa za Oda',
    trackingTitle: 'Ufuatiliaji',
    trackingPlaceholder:
        'Ufuatiliaji wa moja kwa moja utapatikana mara dereva atakapopangwa.',
    orderRouteLabel: 'Njia',
    orderRecipientLabel: 'Mpokeaji',
    orderPackageLabel: 'Kifurushi',
    orderPriceLabel: 'Bei',
    orderPlacedLabel: 'Iliwekwa',
    orderPickupLabel: 'Kuchukua',
    orderPlacedToast: 'Oda imewekwa. Tunakutafutia dereva.',
    cancelOrderTitle: 'Ghairi utoaji huu?',
    cancelOrderBody:
        'Dereva bado hajachukua kifurushi chako. Hatua hii haiwezi kutenduliwa.',
    cancelOrderCta: 'Ghairi Oda',
    cancelOrderConfirm: 'Ndiyo, Ghairi',
    keepOrder: 'Endelea na Oda',
    orderCancelledToast: 'Oda imeghairiwa',
    contactSupport: 'Wasiliana na Msaada',
    backToHome: 'Rudi Nyumbani',
    proofOfDeliveryTitle: 'Uthibitisho wa Ufikishaji',
    receivedByLabel: 'Imepokewa na',
    rateDriverTitle: 'Mpe Nafasi Dereva',
    rateDriverSub: 'Uzoefu wako wa ufikishaji ulikuwaje?',
    youRatedThisDelivery: 'Umeipa nafasi oda hii',
    rateThisDelivery: 'Ipe nafasi oda hii',
    reorder: 'Agiza Tena',
    deliveryDetailsTitle: 'Taarifa za Ufikishaji',
    deliveryNoteLabel: 'Ujumbe',
    recentPlacesTitle: 'Maeneo ya Hivi Karibuni',
    attachPhotoLabel: 'Picha ya kifurushi',
    attachPhotoHint:
        'Ongeza picha ili dereva athibitishe anachokwenda kuchukua.',
    takePhoto: 'Piga Picha',
    chooseFromGallery: 'Chagua kwenye Picha',
    removePhotoLabel: 'Ondoa picha',
  );

  static JhStrings of(JhLang lang) => lang == JhLang.sw ? sw : en;
}
