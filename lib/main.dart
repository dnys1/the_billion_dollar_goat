import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

final openAIProvider = Provider((ref) {
  return OpenAI.instance.build(
    token: '<OPEN AI TOKEN>',
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    isLog: true,
  );
});

final recorderProvider = Provider((ref) => Record());

Future<void> main() async {
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const MyHomePage(),
      ),
      GoRoute(
        path: '/transcribing',
        name: 'transcribing',
        redirect: (context, state) {
          final recordedPath = state.extra as String?;
          if (recordedPath == null) {
            return '/';
          }
          return null;
        },
        builder: (context, state) {
          final recordedPath = state.extra as String;
          return TranscriptionScreen(recordedPath: recordedPath);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      routerConfig: _router,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

final homePageViewModelProvider = ChangeNotifierProvider((ref) {
  final recorder = ref.read(recorderProvider);
  return HomePageViewModel(recorder);
});

class HomePageViewModel with ChangeNotifier {
  HomePageViewModel(this.recorder);

  late String path;
  final Record recorder;
  var isRecording = false;

  Future<void> startRecording() async {
    if (!await recorder.hasPermission()) {
      throw Exception('');
    }
    final documentsDir = await getApplicationDocumentsDirectory();
    path = '${documentsDir.path}/temp.wav';
    await recorder.start(
      path: path,
      encoder: AudioEncoder.wav,
    );
    isRecording = true;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    await recorder.stop();
    isRecording = false;
    notifyListeners();
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homePageViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billion Dollar 🐐'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: viewModel.isRecording
                  ? () async {
                      await viewModel.stopRecording();
                      if (context.mounted) {
                        context
                            .pushNamed('transcribing', extra: viewModel.path)
                            .ignore();
                      }
                    }
                  : viewModel.startRecording,
              child: Text(viewModel.isRecording ? 'Stop' : 'Record'),
            ),
          ],
        ),
      ),
    );
  }
}

final transcriptionScreenViewModelProvider = ChangeNotifierProvider((ref) {
  final openAI = ref.read(openAIProvider);
  return TranscriptionScreenViewModel(openAI);
});

class TranscriptionScreenViewModel with ChangeNotifier {
  TranscriptionScreenViewModel(this.openAI);

  final OpenAI openAI;
  String? transcribedText;

  Future<void> transcribe(String recordedPath) async {
    final transcribeResponse = await openAI.audio.transcribes(
      AudioRequest(file: EditFile(recordedPath, 'garbage')),
    );
    transcribedText = transcribeResponse.text;
    notifyListeners();
  }
}

class TranscriptionScreen extends ConsumerStatefulWidget {
  const TranscriptionScreen({required this.recordedPath, super.key});

  final String recordedPath;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TranscriptionScreenState();
}

class _TranscriptionScreenState extends ConsumerState<TranscriptionScreen> {
  @override
  void initState() {
    super.initState();
    ref
        .read(transcriptionScreenViewModelProvider)
        .transcribe(widget.recordedPath);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(transcriptionScreenViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Transcribing')),
      body: Center(
        child: viewModel.transcribedText == null
            ? const CircularProgressIndicator()
            : Text(viewModel.transcribedText!),
      ),
    );
  }
}
