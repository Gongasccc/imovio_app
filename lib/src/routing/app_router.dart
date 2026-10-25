import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/authentication/presentation/sign_in_screen.dart';
import 'package:imovio/src/features/contacts/presentation/contact_edit_screen.dart';
import 'package:imovio/src/features/contacts/presentation/contacts_screen.dart';
import 'package:imovio/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:imovio/src/features/market_study/presentation/market_study_pdf_screen.dart';
import 'package:imovio/src/features/market_study/presentation/market_study_screen.dart';
import 'package:imovio/src/features/pipeline/presentation/deal_edit_screen.dart';
import 'package:imovio/src/features/pipeline/presentation/pipeline_screen.dart';
import 'package:imovio/src/features/properties/presentation/properties_screen.dart';
import 'package:imovio/src/features/properties/presentation/property_detail_screen.dart';
import 'package:imovio/src/features/properties/presentation/property_new_screen.dart';
import 'package:imovio/src/features/settings/presentation/settings_screen.dart';
import 'package:imovio/src/features/tasks/presentation/task_edit_screen.dart';
import 'package:imovio/src/features/team/presentation/team_screen.dart';
import 'package:imovio/src/features/tasks/presentation/tasks_screen.dart';
import 'package:imovio/src/routing/go_router_refresh_stream.dart';
import 'package:imovio/src/routing/not_found_screen.dart';
import 'package:imovio/src/routing/scaffold_with_nested_navigation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _contactsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'contacts');
final _propertiesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'properties');
final _pipelineNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'pipeline');
final _tasksNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tasks');

enum AppRoute {
  signIn,
  dashboard,
  contacts,
  newContact,
  contact,
  properties,
  newProperty,
  property,
  marketStudy,
  marketStudyPdf,
  pipeline,
  newDeal,
  deal,
  tasks,
  newTask,
  task,
  settings,
  team,
}

const _protectedPrefixes = [
  '/dashboard',
  '/contacts',
  '/properties',
  '/pipeline',
  '/tasks',
  '/settings',
  '/team',
];

/// Ecrã de edição em modo diálogo (ecrã inteiro), acima da navegação.
///
/// Página normal (não "fullscreenDialog") para o gesto de deslizar da
/// esquerda para a direita voltar atrás, como nas apps do telemóvel.
Page<void> _dialogPage(Widget child) => MaterialPage(child: child);

@riverpod
GoRouter goRouter(Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refresh = GoRouterRefreshStream(authRepository.authStateChanges());
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/dashboard',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggedIn = authRepository.currentUser != null;
      if (isLoggedIn && path.startsWith('/signIn')) return '/dashboard';
      if (!isLoggedIn && _protectedPrefixes.any(path.startsWith)) {
        return '/signIn';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/signIn',
        name: AppRoute.signIn.name,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SignInScreen()),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/team',
        name: AppRoute.team.name,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TeamScreen(),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => NoTransitionPage(
          child: ScaffoldWithNestedNavigation(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                name: AppRoute.dashboard.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _contactsNavigatorKey,
            routes: [
              GoRoute(
                path: '/contacts',
                name: AppRoute.contacts.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ContactsScreen()),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: AppRoute.newContact.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) =>
                        _dialogPage(const ContactEditScreen()),
                  ),
                  GoRoute(
                    path: ':id',
                    name: AppRoute.contact.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _dialogPage(
                      ContactEditScreen(contactId: state.pathParameters['id']),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _propertiesNavigatorKey,
            routes: [
              GoRoute(
                path: '/properties',
                name: AppRoute.properties.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PropertiesScreen()),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: AppRoute.newProperty.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) =>
                        _dialogPage(const PropertyNewScreen()),
                  ),
                  GoRoute(
                    path: ':id',
                    name: AppRoute.property.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => PropertyDetailScreen(
                      propertyId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'estudo',
                        name: AppRoute.marketStudy.name,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => MarketStudyScreen(
                          propertyId: state.pathParameters['id']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'pdf',
                            name: AppRoute.marketStudyPdf.name,
                            parentNavigatorKey: _rootNavigatorKey,
                            builder: (context, state) => MarketStudyPdfScreen(
                              propertyId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _pipelineNavigatorKey,
            routes: [
              GoRoute(
                path: '/pipeline',
                name: AppRoute.pipeline.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PipelineScreen()),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: AppRoute.newDeal.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _dialogPage(DealEditScreen(
                      initialContactId: state.uri.queryParameters['contactId'],
                      initialPropertyId:
                          state.uri.queryParameters['propertyId'],
                    )),
                  ),
                  GoRoute(
                    path: ':id',
                    name: AppRoute.deal.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _dialogPage(
                      DealEditScreen(dealId: state.pathParameters['id']),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tasksNavigatorKey,
            routes: [
              GoRoute(
                path: '/tasks',
                name: AppRoute.tasks.name,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TasksScreen()),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: AppRoute.newTask.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _dialogPage(TaskEditScreen(
                      draft: TaskDraft.fromQuery(state.uri.queryParameters),
                    )),
                  ),
                  GoRoute(
                    path: ':id',
                    name: AppRoute.task.name,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _dialogPage(
                      TaskEditScreen(taskId: state.pathParameters['id']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) =>
        const NoTransitionPage(child: NotFoundScreen()),
  );
}
