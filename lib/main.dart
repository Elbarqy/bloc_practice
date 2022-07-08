import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math show Random;

void main() {
  runApp(const MyApp());
}

const names = [
  'Foo',
  'Bar',
  'Baz',
];

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonAction implements LoadAction {
  final PersonUrl url;
  const LoadPersonAction({required this.url}) : super();
}

enum PersonUrl { person1, person2 }

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.person1:
        return "http://127.0.0.1:5500/api/person1.json";
      case PersonUrl.person2:
        return "http://127.0.0.1:5500/api/person1.json";
    }
  }
}

@immutable
class Person {
  final String name;
  final int age;
  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;
}

Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrivedFromCache;
  const FetchResult(
    this.persons,
    this.isRetrivedFromCache,
  );

  @override
  String toString() =>
      'FetchResult (isRetrievedFromCache = $isRetrivedFromCache, persons = $persons)';
}

// class PersonsBloc extends Bloc<LoadAction, FetchResult?> {
//   final Map<PersonUrl, Iterable<Person>> _cache = {};
//   PersonsBloc() : super(null){
//     on<LoadPersonAction>((event, emit) => null)
//   }
// }

extension RandomElement<T> on Iterable<T> {
  T getRandomElement() => elementAt(math.Random().nextInt(length));
}

class NamesCubit extends Cubit<String?> {
  NamesCubit() : super(null);
  void pickRandomName() {
    // state gives you the current state of the cubit
    // * only a getter
    return emit(names.getRandomElement());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final NamesCubit cubit;
  @override
  void initState() {
    super.initState();
    cubit = NamesCubit();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<String?>(
          stream: cubit.stream,
          builder: (context, snapshot) {
            final button = TextButton(
              onPressed: () => cubit.pickRandomName(),
              child: const Text("Pick a random Name"),
            );
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return button;
              case ConnectionState.active:
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(snapshot.data ?? ''),
                    button,
                  ],
                );
              case ConnectionState.done:
                return button;
              case ConnectionState.none:
                return const SizedBox();
            }
          },
        ),
      ),
    );
  }
}
