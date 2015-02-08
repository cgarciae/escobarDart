part of arista_client;

@Component
(
    selector : "vista",
    templateUrl: 'components/vista/vista.html',
    useShadowDom: false
)
class VistaVista
{
    Router router;
    VistaExportable vista = new VistaExportable();
    String eventoID;
    
    List<TipoDeVista> tiposDeVista = const 
    [
        const TipoDeVista (
                'ConstruccionRAJS, Assembly-CSharp', 
                'Construccion RA', 
                'Experimenta tu inmueble en Realidad Aumentada'),
                
        const TipoDeVista (
                'InfoContactoJS, Assembly-CSharp', 
                'Informacion y Contacto', 
                'Vista con informacion general y opciones de contacto'),
                
        const TipoDeVista (
                'MultimediaJS, Assembly-CShar',
                'Multimedia',
                'Vista para carrusel de y imagenes, proximamente videos'
                ),
                
        const TipoDeVista (
                'MapaConstruccionJS, Assembly-CSharp',
                'Ubicación',
                'Muestra la ubicación de tu proyecto facilmente'
                )
     ];
    
    List<TipoElementoInfo> tiposElementoInfo = const 
    [
        const TipoElementoInfo (
                'TituloInfoJS, Assembly-CSharp', 
                'Titulo', 
                'Experimenta tu inmueble en Realidad Aumentada'),
                
        const TipoElementoInfo (
                'ImagenInfoJS, Assembly-CSharp', 
                'Imagen', 
                'Vista con informacion general y opciones de contacto'),
                
        const TipoElementoInfo (
                'InfoTextoJS, Assembly-CSharp',
                'Descripción',
                'Vista para carrusel de y imagenes, proximamente videos'
                )
     ];
    
    List<TipoElementoContacto> tiposElementoContacto = const
    [
        const TipoElementoContacto (
                'LlamarContactoJS, Assembly-CSharp' ,
                'Contactar',
                'Permite llamar con un toque'
        )
    ];
    
    
    VistaVista (RouteProvider routeProvider, this.router)
    {
        initVista (routeProvider);
        print("constructor vistaVista");
    }
    
    initVista (RouteProvider routeProvider) async
    {
        var id = routeProvider.parameters['vistaID'];
        eventoID = routeProvider.parameters['eventoID'];
        
        if (id == null)
        {
            print ('NUEVA VISTA');
            //Crear nuevo evento
            IdResp resp = await newFromCollection ('vista');
            
            if (resp.success)
            {
                vista.id = resp.id;
            }
            else
            {
                print (resp.error);
            }
        }
        else
        {
            print ('CARGAR VISTA');
            //Cargar vista
            VistaExportableResp resp = await getFromCollection
            (
                VistaExportableResp, 
                'vista', 
                id
            );
            
            if (! resp.success)
                return print (resp.error);

            
            vista = resp.vista;
            icono = vista.icon.urlTextura.split (r'/').last;
            urlIcono = 'images/webapp/${icono}.png';
        }
    }
    
    save () async
    {
        Resp resp = await saveInCollection ('vista', vista);

        if (resp.success)
            router.go('evento', {'eventoID' : eventoID});
        else
            print (resp.error);
    }

    
    
    seleccionarTipoVista (TipoDeVista tipo)
    {

        vista.type__ = tipo.type__;
        setIcono();
        switch(vista.type__){
            case 'ConstruccionRAJS, Assembly-CSharp':
                vista
                    ..muebles = []
                    ..cuartos = []
                    ..target = new AristaImageTarget();
                
                //TODO: Vista ya no tiene el campo "modelo", ahora tiene "modeloId" que es el _id
                //de Mongo del UnityObject. Verificar si es null y pedir uno nuevo, sino pedir el existente.
                
                break;
            case 'InfoContactoJS, Assembly-CSharp':
                vista
                    ..elementosContacto = []
                    ..elementosInfo = [];
                break;
            case 'MultimediaJS, Assembly-CShar':
                break;
            case 'MapaConstruccionJS, Assembly-CSharp':
                break;
            default:
                break;
                
        }
    }
    
    seleccionarTipoElemento (dynamic tipo, dynamic elem)
    {
        elem.type__ = tipo.type__;
    } 
    
    
    String icono = '';
    void setIcono ()
    {
        switch(vista.type__){
            case 'ConstruccionRAJS, Assembly-CSharp':
                icono = "3D";
                break;
            case 'InfoContactoJS, Assembly-CSharp':
                icono = "info";
                break;
            case 'MultimediaJS, Assembly-CShar':
                icono = "Galeria";
                break;
            case 'MapaConstruccionJS, Assembly-CSharp':
                icono = "Ubicacion";
                break;
            default:
                icono= "missing_image";
                break;
                
        }
        
        vista.icon.web = false;
        vista.icon.path = "HG/Materials/App/$icono";
        urlIcono = 'images/webapp/${icono}.png';
    }
    String urlIcono = '';
    
        
    void NuevoMueble ()
    {
        if (vista.muebles == null)
            vista.muebles = [];
        vista.muebles.add(new ElementoConstruccion());
        
    }
    
    void NuevoCuarto ()
    {
        if (vista.cuartos == null)
                    vista.cuartos = [];
        vista.cuartos.add(new ElementoConstruccion());
        
    }
    
    void EliminarElemento (dynamic elem, List<dynamic> listElem)
    {
        listElem.remove(elem);        
        
    }
    
    guardarUrlObjeto(String s, _){
        //TODO: Vista ya no tiene el campo "modelo", ademas ya "path" es
        //una propiedad "get". Mirar el nuevo API para ver como interactuar con ObjetoUnity.
        vista.modelo.path = s;
    }
    
    guardarUrlTarget(String s, _){
        vista.target.path = s;
    }
    
    guardarUrlImagenElemento(String s, elemento){
        elemento.urlImagen = s;
    }
    
    guardarUrlInfo(String s, info){
        info.path = s;
    }
    
    guardarUrlTextura(String s, textura){
        textura.urlTextura = s;
    }
    
    upload (dom.MouseEvent event, String urlObjeto, Function guardar, [dynamic elemento])
    {
        String url = 'private/file';
        String method;
        
        if(urlObjeto == null || urlObjeto == ""){
            method = Method.POST;
            print("no existe, new");
        }
        else
        {   
            var id = urlObjeto.split('/').last;
            url += "/${id}";
            method = Method.PUT;
            print("actualizo");
        }   
    
        dom.FormElement form = getFormElement (event);
                    
        formRequestDecoded (IdResp, method, url, form)
        
        .then(doIfSuccess((IdResp resp)
        {   
            print (resp.success);
            guardar('public/file/${resp.id}', elemento);
            return saveInCollection('vista', vista);
        }))
        
        .then(doIfSuccess((Resp resp)
        {
            dom.window.location.reload(); 
        }));
    }
    
    uploadObjetoUnityUserFile (dom.MouseEvent event) async
    {
        dom.FormElement form = getFormElement (event);
        
        if (notNullOrEmpty (vista.modeloId))
        {
            IdResp resp = await formRequestDecoded
            (
                IdResp,
                Method.PUT,
                "private/objetounity/${vista.modeloId}/modelfile",
                form
            );
            
            if (! resp.success)
            {
                print ("Upload Failed: ${resp.error}");
            }
        }
        
    }
}



class TipoDeVista
{
    final String nombre;
    final String descripcion;
    final String type__;
    
    const TipoDeVista (this.type__, this.nombre, this.descripcion);
}

class TipoElementoContacto
{
    final String nombre;
    final String descripcion;
    final String type__;
    
    const TipoElementoContacto (this.type__, this.nombre, this.descripcion);
}

class TipoElementoInfo
{
    final String nombre;
    final String descripcion;
    final String type__;
    
    const TipoElementoInfo (this.type__, this.nombre, this.descripcion);
}
