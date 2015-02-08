part of arista_client;


@Component
(
    selector : "home",
    templateUrl: 'components/home/home.html',
    useShadowDom: false
)
class HomeVista
{
    
    User user = new User();
    List<Evento> eventos = [];
    String url = '';
    
    Router router;
    
    HomeVista (this.router)
    {
        getUser();
    }
    
    bool get isAdmin => loggedAdmin;
    
    getUser ()
    {
        requestDecoded(PanelInfo, Method.GET,'/private/user/panelinfo')
        .then ((PanelInfo info)
        {
            user = info.user;
            eventos = info.eventos;
            
        })
        .catchError((e)
        {
            print ('Error type ${e.runtimeType}');
            router.go('login', {});
        },
        test: (e) => e is dom.ProgressEvent);
        
    }
    
    nuevoEvento ()
    {
        requestDecoded(IdResp, Method.POST, 'private/evento')
        
        .then (doIfSuccess ((resp) => addEventId (resp.id)));
    }
    
    Future<Resp> addEventId  (String eventID)
    {
        var evento = new Evento()
                ..id = eventID
                ..nombre = 'Nuevo Evento'
                ..descripcion = 'Descripcion';
        
        eventos.add(evento);
            
        return saveInCollection('evento', evento);
    }
    
    
    ver (Evento e)
    {
        print ("VER EVENTO");
        router.go('evento', {'eventoID': e.id});
    }
    
    eliminar (Evento e, dom.MouseEvent event)
    {
        event.stopImmediatePropagation();
        
        () async
        {
            print ("ELIMINAR");
            
            Resp resp = await deleteFromCollection ('evento', e.id);
    
            if (resp.success)
                eventos.remove (e);
        }();
    }
    
//    upload (dom.MouseEvent event)
//    {
//        dom.FormElement form = (event.target as dom.ButtonElement).parent as dom.FormElement;
//        
//        formRequestDecoded('private/new/file', form, IdResp).then((IdResp resp)
//        {
//            print (resp.success);
//            url = 'public/get/file/${resp.id}';
//        });
//    }
}

