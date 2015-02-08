part of arista_server;

//POST private/objetounity () -> ObjetoUnitySendResp
//PUT private/objetounity (json ObjetoUnity) -> Resp
//GET private/objetounity/:id () -> ObjetoUnitySendResp
//DELETE private/objetounity/:id () -> Resp
//POST|PUT private/objetounity/:id/userfile (form FormElement) ->
//ADMIN >> POST|PUT private/objetounity/:id/modelfile/:system (form FormElement) -> ObjetoUnitySendResp
//GET private/user/objetounitymodels () -> ObjetoUnitySendListResp


@app.Route('/private/objetounity', methods: const [app.POST])
@Encode()
newObjetoUnity (@app.Attr() MongoDb dbConn) async
{   
    try
    {
        var obj = new ObjetoUnitySend()
            ..id = new ObjectId().toHexString()
            ..name = 'Nuevo Modelo'
            ..version = 0
            ..updatePending = false
            ..owner = (session["id"] as ObjectId).toHexString();
        
        await dbConn.insert (Col.objetoUnity, obj);
        
        return new ObjetoUnitySendResp()
            ..success = true
            ..obj = obj;
    }
    catch (e, stacktrace)
    {
        return new Resp()
            ..success = false
            ..error = e.toString() + stacktrace.toString();
    }
}

@app.Route('/private/objetounity', methods: const [app.PUT])
@Encode()
putObjetoUnity (@app.Attr() MongoDb dbConn, @Decode() ObjetoUnity obj) async
{
    print (encodeJson(obj));
    try 
    {
        await dbConn.update
        (
            Col.objetoUnity,
            where.id (StringToId(obj.id)),
            obj,
            override: false
        );
        
        return new Resp()
            ..success = true;
    }
    catch (e, stacktrace)
    {
        return new Resp()
            ..success = false
            ..error = e.toString() + stacktrace.toString();
    }
}

@app.Route('/private/objetounity/:id', methods: const [app.GET])
@Encode()
getObjetoUnity (@app.Attr() MongoDb dbConn, String id) async
{
    try
    {   
        ObjetoUnitySend obj = await dbConn.findOne
        (
            Col.objetoUnity,
            ObjetoUnitySend,
            where.id(StringToId(id))
        );
        
        if (obj == null)
            return new Resp()
                ..success = false
                ..error = "Objeto Unity not found";
        
        
        return new ObjetoUnitySendResp()
            ..success = true
            ..obj = obj;
    }
    catch (e, stacktrace)
    {
        return new Resp()
            ..success = false
            ..error = e.toString() + stacktrace.toString();
    }
}

@app.Route('/private/objetounity/:id', methods: const [app.DELETE])
@Encode()
deleteObjetoUnity (@app.Attr() MongoDb dbConn, String id) async
{
    try
    {   
        await dbConn.remove
        (
            Col.objetoUnity,
            where.id(StringToId(id))
        );

        return new Resp()
            ..success = true;
    }
    catch (e, stacktrace)
    {
        return new Resp()
            ..success = false
            ..error = e.toString() + stacktrace.toString();
    }
}


@app.Route('/private/objetounity/:id/userfile', methods: const [app.POST, app.PUT], allowMultipartRequest: true)
@Encode()
postOrPutObjetoUnityUserFile (@app.Attr() MongoDb dbConn, @app.Body(app.FORM) Map form, String id) async
{
    try
    {
        Resp resp;
        IdResp idResp;
        ObjetoUnitySendResp objResp;
        
        resp = await getObjetoUnity(dbConn, id);
        
        if (! resp.success)
            return resp;
        
        objResp = resp as ObjetoUnitySendResp;
        
        if (notNullOrEmpty (objResp.obj.userFileId))
        {
            resp = await updateFile 
                    (dbConn, form, objResp.obj.userFileId);
        }
        else
        {
            resp = await newFile(dbConn, form);
        }
        
        
        if (! resp.success)
            return resp;
        
        idResp = resp as IdResp;
        
        await dbConn.update
        (
            Col.objetoUnity,
            where
                .id (StringToId (id)),
            modify
                .set('userFileId', StringToId (idResp.id))
                .set('updatePending', true)
        );
        
        return idResp; 
    }
    catch (e, stacktrace)
    {
        return new Resp()
            ..success = false
            ..error = e.toString() + stacktrace.toString();
    }
}

Future saveOrUpdateModelFile (MongoDb dbConn, Map form, ObjetoUnitySend obj, String system) async
{
    String fileId;
    
    if (system == 'android')
    {
        fileId = obj.modelIdAndroid;
    }
    else if (system == 'ios')
    {
        fileId = obj.modelIdIOS;
    }
    else if (system == 'windows')
    {
        fileId = obj.modelIdWindows;
    }
    else if (system == 'mac')
    {
        fileId = obj.modelIdMAC;
    }
    else
    {
        return new Resp()
            ..success = false
            ..error = "Invalid system path variable: ${system}";
    }
    
    Resp resp;
    IdResp idResp;
    
    if (fileId == null)
    {
        resp = await newFile (dbConn, form);
    }
    else
    {
        resp = await updateFile(dbConn, form, fileId);
    }
    
    if (resp is IdResp && resp.success)
    {
        idResp = resp;
    }
    else
    {
        return resp;
    }
    
    if (system == 'android')
    {
        obj.modelIdAndroid = idResp.id;
        obj.updatedAndroid = true;
    }
    else if (system == 'ios')
    {
        obj.modelIdIOS = idResp.id;
        obj.updatedIOS = true;
    }
    else if (system == 'windows')
    {
        obj.modelIdWindows = idResp.id;
        obj.updatedWindows = true;
    }
    else if (system == 'mac')
    {
        obj.modelIdMAC = idResp.id;
        obj.updatedMAC = true;
    }
    
    return idResp;   
}

@app.Route('/private/objetounity/:id/modelfile/:system', methods: const [app.POST, app.PUT], allowMultipartRequest: true)
@Encode()
@Secure(ADMIN)
Future newOrUpdateObjetoUnityModelFile (@app.Attr() MongoDb dbConn, @app.Body(app.FORM) Map form, String id, String system) async
{
    try
    {
        Resp objResp = await getObjetoUnity(dbConn, id);
                
        if (! objResp.success)
            return objResp;
        
        ObjetoUnitySend obj = (objResp as ObjetoUnitySendResp).obj;
        
        Resp resp = await saveOrUpdateModelFile (dbConn, form, obj, system);
        
        if (! resp.success)
            return resp;
        
        await dbConn.update
        (
            Col.objetoUnity,
            where.id (StringToId (id)),
            obj,
            override: false
        );
        
        return objResp;
        
    }
    catch (e, stacktrace)
    {
        return new Resp()
            ..success = false
            ..error = e.toString() + stacktrace.toString();
    }
}

newOrUpdateScreenshot (MongoDb dbConn, Map form, ObjetoUnitySend obj) async
{
    Resp resp;
    IdResp idResp;
    
    if (notNullOrEmpty (obj.screenshotId))
    {
        resp = await updateFile(dbConn, form, obj.screenshotId);
    }
    else
    {
        resp = await newFile(dbConn, form);
    }
    
    idResp = resp as IdResp;
    
    if (idResp == null)
        return resp;
    
    obj.screenshotId =  idResp.id;
    
    await dbConn.update
    (
        Col.objetoUnity,
        where.id (StringToId (obj.id)), 
        modify.set ('screenshotId', StringToId (idResp.id))
    );
    
    return idResp;
}

@app.Route ('/private/objetounity/:id/screenshot', methods: const [app.POST, app.PUT], allowMultipartRequest: true)
@Encode ()
@Secure (ADMIN)
Future newOrUpdateObjetoUnityScreenshot (@app.Attr() MongoDb dbConn, @app.Body(app.FORM) Map form, String id) async
{
    try
    {
        ObjetoUnitySendResp objResp;
        IdResp idResp;
        Resp resp = await getObjetoUnity(dbConn, id);
                
        if (! resp.success)
            return resp;
        
        objResp = resp as ObjetoUnitySendResp;
        
        //Updates screenshotId, return IdResp
        return newOrUpdateScreenshot (dbConn, form, objResp.obj);
    }
    catch (e, stacktrace)
    {
        return new Resp.failed
        (
            e.toString() + stacktrace.toString()
        );
    }
}

@app.Route ('/private/objetounity/:id/publish', methods: const [app.GET])
@Encode ()
@Secure (ADMIN)
Future publishObjetoUnity (@app.Attr() MongoDb dbConn, String id) async
{
    ObjetoUnitySendResp objResp;
    
    Resp resp = await getObjetoUnity(dbConn, id);
    
    if (! resp.success)
        return resp;
    
    objResp = resp as ObjetoUnitySendResp;
    
    if (! objResp.obj.updatedAll)
        return new Resp.failed
        (
            "No se han actualizado todos los modelos del Objetos Unity"
        );
    
    await dbConn.update
    (
        Col.objetoUnity,
        where.id(StringToId(id)),
        modify
            .set('updatePending', false)
            .inc('version', 1)
    );
    
    return new Resp.sucess();
}





@app.Route('/private/user/objetounitymodels', methods: const [app.GET])
@Encode()
userModels (@app.Attr() MongoDb dbConn) async
{
    try
    {  
        List<ObjetoUnitySend> objs = await dbConn.find
        (
            Col.objetoUnity,
            ObjetoUnitySend,
            where.eq('owner', userId)
        );

        return new ObjetoUnitySendListResp()
            ..success = true
            ..objs = objs;
    }
    catch (e, stacktrace)
    {
        return new Resp()
            ..success = false
            ..error = e.toString() + stacktrace.toString();
    }
}

@app.Route ('/private/objetounity/pending', methods: const [app.GET], allowMultipartRequest: true)
@Encode ()
@Secure (ADMIN)
Future getObjetoUnityPending (@app.Attr() MongoDb dbConn) async
{
    try
    {
        List<ObjetoUnitySend> objs = await dbConn.find
        (
            Col.objetoUnity,
            ObjetoUnitySend,
            where
                .eq ('updatePending', true)
        );
        
        return new ObjetoUnitySendListResp()
            ..success = true
            ..objs = objs;
    }
    catch (e, stacktrace)
    {
        return new Resp()
            ..success = false
            ..error = e.toString() + stacktrace.toString();
    }
}