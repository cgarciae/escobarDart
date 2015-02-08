part of arista_server;


@app.Route("/private/evento", methods: const[app.POST])
@Encode()
Future<IdResp> newEvent(@app.Attr() MongoDb dbConn) async
{
    EventoCompleto evento = new EventoCompleto()
        ..id = new ObjectId().toHexString()
        ..active = false;

    await dbConn.insert (Col.maquina, evento);

    var userId = session['id'];
    
    if (userId == null)
        return new Resp()
            ..success = false
            ..error = 'User not found';

    await dbConn.update
    (
        Col.user,
        where.id (userId), 
        modify.push ('eventos', StringToId (evento.id))
    );

    return new IdResp()
      ..success = true
      ..id = evento.id;
}

@app.Route("/private/evento", methods: const [app.PUT])
@Encode()
Future<IdResp> saveEvent(@app.Attr() MongoDb dbConn, @Decode() Evento evento) async
{
    await dbConn.update(Col.maquina, where.id(StringToId(evento.id)), evento);

    return new IdResp()
        ..success = true
        ..id = evento.id;
}

@app.Route("/private/evento/:id", methods: const [app.GET])
@Encode()
Future<Evento> getEvento(@app.Attr() MongoDb dbConn, String id) async
{
    return dbConn.findOne(Col.maquina, Evento, where.id(StringToId(id)));
}

@app.Route("/private/evento/:id", methods: const [app.DELETE])
@Encode()
deleteEvento(@app.Attr() MongoDb dbConn, String id) async
{
    var eventoId = StringToId(id);
    ObjectId userID = session['id'];

    await dbConn.update (Col.user, where.id(userID), modify.pull('eventos', eventoId));
    await dbConn.remove (Col.maquina, where.id(eventoId));
    
    return new Resp()..success = true;
}

@app.Route("/private/activate/:status/evento/:eventoID")
@Encode()
Future<Resp> activateEvento(@app.Attr() MongoDb dbConn, bool status, String eventoID) async
{
    String aristaRecoID;

    EventoCompleto evento = await dbConn.findOne
    (
        Col.maquina, 
        EventoCompleto, 
        where.id(StringToId(eventoID))
    );
    
    if (evento == null) 
        return new Resp()
            ..success = false
            ..error = "Evento not found";

    aristaRecoID = evento.cloudRecoTargetId;
    
    AristaCloudRecoTarget reco = await dbConn.findOne
    (
        Col.recoTarget,
        AristaCloudRecoTarget, 
        where.id(StringToId(aristaRecoID))
    );
    
    if (reco == null)
        return new Resp()
            ..success = false
            ..error = "Cloud Reco not found";

    await dbConn.update
    (
        Col.maquina,
        where.id (StringToId (eventoID)),
        modify.set('active', status)
    );
    
    QueryMap map = await makeVuforiaRequest 
    (
        Method.PUT, 
        "/targets/${reco.targetId}", 
        conv.JSON.encode
        ({
            "active_flag": status
        }), 
        ContType.applicationJson
    )
    .send()
    .then (streamResponseToJSON)
    .then (MapToQueryMap);
        

    if (map.result_code == "Success") 
    {
        return new Resp()..success = true;
    } 
    else 
    {
        return new Resp()
            ..success = false
            ..error = map.result_code;
    }
}

@app.Route('/all/evento')
@Encode()
allEventos(@app.Attr() MongoDb dbConn) 
{
    return dbConn.find(Col.maquina, Evento);
}

@app.Route('/export/evento/:id')
@Encode()
exportEvento(@app.Attr() MongoDb dbConn, String id) async
{
    EventoExportable evento = await dbConn.findOne
    (
        Col.maquina,
        EventoExportable, 
        where.id (StringToId (id))
    );

    print ("EE 1");
    await BuildEvento(dbConn, evento);
    
    print ("EE 2");
    Resp resp = await validEvento (evento);
    
    if (resp.success)
    {
        return new EventoExportableResp()
            ..success = true
            ..evento = evento;
    }
    else
    {
        return resp..error = "Evento Invalido: ${resp.error}";
    }
}

Future<EventoExportable> BuildEvento(MongoDb dbConn, EventoExportable evento) async
{
    print ("BE 1");
    var objIDs = evento.viewIds.map (StringToId).toList();

    evento.vistas = await dbConn.find
    (
        Col.vista, 
        VistaExportable, 
        where.oneFrom('_id', objIDs)
    );

    var futures = evento.vistas.map((VistaExportable vista) 
            => buildVista(dbConn, vista)).toList();
    
    await Future.wait (futures);
    
    return evento;
}

Future<Resp> validEvento (EventoExportable evento) async
{
    if (evento.id == null || evento.id == "")
        return new Resp()
            ..success = false
            ..error = "Id de Evento Invalida";
    
    if (evento.active == null || ! evento.active)
        return new Resp()
            ..success = false
            ..error = "Evento inactivo";
    
    if (evento.cloudRecoTargetId == null || evento.cloudRecoTargetId == "")
        return new Resp()
            ..success = false
            ..error = "Target ID Invalida";
    
    
    List<VistaExportable> list = [];
    for (VistaExportable vista in evento.vistas)
    {
        Resp resp = await validVista (vista);
        if (resp.success)
            list.add (vista);
        else
            print (resp.error);
    }
    
    evento.vistas = list;
    
    if (evento.vistas.length == 0)
        return new Resp()
            ..success = false
            ..error = "Ninguna vista valida disponible";
    
    return new Resp()..success = true;
}