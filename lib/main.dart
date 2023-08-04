import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide AWSApiConfig;
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:amplify_core/amplify_config.dart';

final openAIProvider = Provider((ref) {
  return OpenAI.instance.build(
    token: '<OPEN AI TOKEN>',
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    enableLog: true,
  );
});

final recorderProvider = Provider((ref) => Record());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final amplifyConfig = AWSAmplifyConfig(
    api: AWSApiConfig(
      endpoints: {
        'graphql': AWSApiEndpointConfig.appSync(
          endpoint: Uri.parse(
              'https://vf7ldpesgjftlo6n6cfq3vgrge.appsync-api.us-west-2.amazonaws.com/graphql'),
          region: 'us-west-2',
          authMode: const AWSApiAuthorizationMode.apiKey(
              'da2-7qhptmrpsnckzao3zbfcfht53m'),
        ),
      },
    ),
  );
  await Amplify.addPlugin(AmplifyAPI());
  await Amplify.configure(amplifyConfig.toCli().toString());
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

  final textController = TextEditingController();

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
            TextField(
              controller: viewModel.textController,
              maxLines: 5,
            ),
            ElevatedButton(
              onPressed: () async {
                // final response = Amplify.Query.completeChat(
                //   input: ChatCompletionInput(prompt: prompt),
                // );
                final response = await Amplify.API
                    .query(
                      request: GraphQLRequest<String>(
                        document: r'''
                          query CompleteChat($prompt: String!) {
                            completeChat(input: { prompt: $prompt })
                          }
                          ''',
                        variables: {'prompt': viewModel.textController.text},
                      ),
                    )
                    .response;
                safePrint('Response: $response');
              },
              child: const Text('Complete'),
            ),
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
