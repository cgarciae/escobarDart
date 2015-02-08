part of arista_client;

Future<bool> get serverUserLoggedIn async
{
    Resp resp = await requestDecoded
    (
        Resp,
        Method.GET,
        'user/loggedin'
    );
    

    storage['logged'] = resp.success.toString();
    
    
    return resp.success;
}

Future<bool> get serverUserAdmin async
{
    BoolResp resp = await requestDecoded
    (
        BoolResp,
        Method.GET,
        'private/user/isadmin'
    );
    
    print ("Is admin? ${resp.value}");
    
    var isAdmin = (resp.success && resp.value);
    
    storage['admin'] = isAdmin.toString();
    
    return isAdmin;
}

void recipeBookRouteInitializer(Router router, RouteViewFactory view) 
{
    
    
    authenticate2 (RoutePreEnterEvent event)
    {
        event.allowEnter (() async
        {
            bool logged = await serverUserLoggedIn;
            
            if (! logged)
                router.go
                (
                    'login', {},
                    forceReload: true
                );
            
            return logged;
        }());          
    }
    
    authenticateAdmin2 (RoutePreEnterEvent event)
    {
        event.allowEnter (() async
        {
            bool logged = await serverUserLoggedIn;
            
            if (! logged)
            {
                router.go
                (
                    'login', {},
                    forceReload: true
                );
                return false;
            }
            
            bool admin = await serverUserAdmin;
            
            print ("Auth admin $admin");
            
            if (! admin)
            {
                router.go
                (
                    'home', {},
                    forceReload: true
                );
                return false;
            }
            
            return true;
        }());          
    }
    
    view.configure(
    {
        'login': ngRoute
        (
            path: '/login',
            defaultRoute: true,
            enter : view ('view/login_view.html'),
            preEnter: (RoutePreEnterEvent event)
            {
                event.allowEnter (() async
                {
                    print ("Loggin in");
                    
                    bool logged = await serverUserLoggedIn;
                    
                    if (logged)
                        router.go('home', {}, forceReload: true);
                    
                    return ! logged;
                }());          
            },
            mount: 
            {
                'nuevo' : ngRoute
                (
                    path: '/nuevo',
                    enter: view ('view/nuevo_usuario_view.html')
                )
            }
        ),
        
        'home': ngRoute
        (
            path: '/home',
            enter: view ('view/home_view.html'),
            preEnter: authenticate2
        ),
                
        'evento': ngRoute 
        (
            path: '/evento/:eventoID',
            preEnter: (RoutePreEnterEvent event)
            {   
                var id = event.parameters['eventoID'];
                
                if (id == null)
                {
                    router.go('home', {}, forceReload: true);
                    return;
                }
                
                authenticate2 (event);
                
            },
            enter: view ('view/evento_view.html')
        ),
        
        'vista' : ngRoute
        (
            path: '/vista/:eventoID/:vistaID',
            preEnter: (RoutePreEnterEvent event)
            {   
                event.parameters.keys.forEach(print);
                
                var eventoID = event.parameters['eventoID'];
                var viewID = event.parameters['vistaID'];
                
                if (viewID == null || eventoID == null)
                {
                    dom.window.alert("eventoID $eventoID, viewID $viewID");
                    router.go('home', {}, forceReload: true);
                    return;
                }
                
                authenticate2(event);
            },
            enter: view ('view/vista_view.html')
        ),
        
        'admin' : ngRoute
        (
            path: '/admin',
            enter: view('view/admin_view.html'),
            preEnter: authenticateAdmin2
        ),
        
        'adminModel' : ngRoute
        (
            path: '/admin/model',
            enter: view('view/model_view.html'),
            preEnter: authenticateAdmin2
        ),
        
        'A' : ngRoute 
        (
            path : '/A/:parA',
            enter: (RouteEnterEvent e)
            {
                print ('ENTERED A');
                e.parameters.keys.forEach(print);
            },
            mount: 
            {
                'B' : ngRoute
                (
                    path: '/B/:parB',
                    enter: (RouteEnterEvent e)
                    {
                        print ('ENTERED B');
                        e.parameters.keys.forEach(print);
                    }
                )
            }
        
        ),
        
        'B' : ngRoute
        (
            path: '/A/:A/B/:B',
            enter: (RouteEnterEvent e)
            {
                print ('BBB');
                e.parameters.keys.forEach(print);
            }
        )
        
  });
} 


checkLogin () async
{
    IdResp resp = await requestDecoded
    (
         IdResp,
         Method.GET,
         "user/loggedin"
     );
    
    if (resp.success)
        storage['id'] = resp.id;
    else
        storage.remove('id');
}

checkAdmin () async
{
    IdResp resp = await requestDecoded
    (
         IdResp,
         Method.GET,
         "private/user/isadmin"
     );
    
    if (resp.success)
        storage['admin'] = true.toString();
    else
        storage.remove('admin');
}

