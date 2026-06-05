import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/scan_repository_impl.dart';
import 'domain/usecases/analyze_url_usecase.dart';
import 'domain/usecases/get_scan_history_usecase.dart';
import 'presentation/blocs/detection/detection_bloc.dart';
import 'presentation/blocs/history/history_bloc.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env — Single Source of Truth for AI parameters
  await dotenv.load(fileName: '.env');

  // Initialize Hive local database
  await Hive.initFlutter();
  await Hive.openBox<String>(AppConstants.scanHistoryBox);

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const PhisIonApp());
}

class PhisIonApp extends StatelessWidget {
  const PhisIonApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Dependency Injection (manual DI — SOLID) ────────────────────────────
    final repository = ScanRepositoryImpl();
    final analyzeUrlUseCase = AnalyzeUrlUseCase(repository);
    final getHistoryUseCase = GetScanHistoryUseCase(repository);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DetectionBloc(
            analyzeUrlUseCase: analyzeUrlUseCase,
          ),
        ),
        BlocProvider(
          create: (_) => HistoryBloc(
            getScanHistoryUseCase: getHistoryUseCase,
            repository: repository,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
