import 'package:angular/angular.dart';
import 'package:angular/routing/module.dart';
import 'package:angular/application_factory.dart';
import 'package:logging/logging.dart';
import 'package:redstone_mapper/mapper.dart';
import 'package:redstone_mapper/mapper_factory.dart';
import 'package:escobardart/arista_client.dart';
import 'package:escobardart/arista.dart';
import 'dart:html' as dom;
import 'dart:async';

@MirrorsUsed(targets: const[
  'angular',
  'angular.core',
  'angular.core.dom',
  'angular.filter',
  'angular.perf',
  'angular.directive',
  'angular.routing',
  'angular.core.parser',
  'NodeTreeSanitizer'
  ],
  override: '*')
import 'dart:mirrors';

class MyAppModule extends Module
{
    MyAppModule()
    {
        bind (LoginVista);
        bind (HomeVista);
        bind (EventoVista);
        bind (VistaVista);
        bind (NuevoUsuarioVista);
        bind (AdminVista);
        bind (ModelVista);
        bind (RouteInitializerFn, toValue: recipeBookRouteInitializer);
        bind (NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
    }
}

class ListInt
{
    @Field() List<int> list;
}

void main()
{
    bootstrapMapper();

    Logger.root.level = Level.FINEST;
    Logger.root.onRecord.listen((LogRecord r) { print(r.message); });

    applicationFactory()
        .addModule(new MyAppModule())
        .rootContextType (MainController)
        .run();
}
