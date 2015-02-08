part of arista_server;

Future<Map> uploadImageToVuforia (String method, String path, List<int> imageData, String metadata) async
{
    var base64Image = crypto.CryptoUtils.bytesToBase64 (imageData);
    var metadataBytes = crypto.CryptoUtils.bytesToBase64 (metadata.codeUnits);
    
    String body = conv.JSON.encode
    ({
        "name": metadata,
        "width" : 1.0,
        "image" : base64Image,
        "application_metadata" : metadataBytes
    });
    
    http.StreamedResponse resp = await makeVuforiaRequest(method, path, body, ContType.applicationJson).send();
    
    print ("Request headers ${resp.request.headers}");
    print ("Response headers ${resp.headers}");
        
    return resp.stream.toList()
        .then (flatten)
        .then(bytesToJSON);
}

Future<Map> streamResponseToJSON (http.StreamedResponse resp)
{
    return resp.stream.toList()
        .then (flatten)
        .then (bytesToJSON);
}

@app.Route("/private/vuforiaimage/:eventoID", methods: const [app.POST], allowMultipartRequest: true)
@Encode()
newImageVuforia(@app.Attr() MongoDb dbConn, @app.Body(app.FORM) Map form, String eventoID) async
{
    String imageID;
    
    HttpBodyFileUpload file = form ['file'];
    var gridFS = new GridFS (dbConn.innerConn);
    var input = new Stream.fromIterable([file.content]);
    var gridIn = gridFS.createFile(input, file.filename)
        ..contentType = file.contentType.value;
    
            
    await gridIn.save();
            
    QueryMap map = await uploadImageToVuforia
    (
         Method.POST, 
         "/targets", 
         file.content, 
         eventoID
     )
    .then (MapToQueryMap);
        
    print (map);
        
    if (map.result_code == "TargetCreated")
    {
        imageID = gridIn.id.toHexString();
        String targetID = map.target_id;
        
        return createRecoTarget (dbConn, eventoID, imageID, targetID);
    }
    else
    {
        await deleteFile (dbConn, imageID);
                
        return new Resp()
            ..success = false
            ..error = map.result_code;
    }
}

@app.Route("/private/vuforiaimage/:eventoID", methods: const [app.PUT], allowMultipartRequest: true)
@Encode()
updateImageVuforia(@app.Attr() MongoDb dbConn, @app.Body(app.FORM) Map form, String eventoID) async
{
    
    HttpBodyFileUpload file = form ['file'];
    
    Evento evento = await dbConn.findOne
    (
        Col.maquina,
        Evento,
        where.id (StringToId (eventoID))
    );
    
    if (evento == null) return new Resp()
        ..success = false
        ..error = "Evento not found";
    
    var cloudRecoID = evento.cloudRecoTargetId;
    
    AristaCloudRecoTarget reco = await dbConn.findOne
    (
        Col.recoTarget,
        AristaCloudRecoTarget, 
        where.id (StringToId (cloudRecoID))
    );
        
    if (reco == null) return new Resp ()
        ..success = false
        ..error = "Cloud Reco found";
    
    var targetID = reco.targetId;
    var imageID = reco.imageId;
    
    Resp resp = await updateFile (dbConn, form, imageID);

    if (! resp.success)
        return resp;
        
    QueryMap map = await uploadImageToVuforia (Method.PUT, "/targets/${targetID}", file.content, eventoID)
            .then(MapToQueryMap);
        
    if (map.result_code == "TargetCreated" || map.result_code == "Success")
    {
        return new Resp()
            ..success = true;
    }
    else
    {
        return new Resp()
            ..success = false
            ..error = map.result_code;
    }
}

@app.Route("/public/vuforiatarget/:eventoID", methods: const [app.GET])
@Encode()
Future<Resp> getVuforiaTarget(@app.Attr() MongoDb dbConn, String eventoID) async
{
    Evento evento = await dbConn.findOne
    (
        Col.maquina,
        Evento,
        where.id (StringToId (eventoID))
    );
    
    if (evento == null) return new Resp()
        ..success = false
        ..error = "Evento not found";
    
    AristaCloudRecoTarget reco = await dbConn.findOne
    (
        Col.recoTarget, 
        AristaCloudRecoTarget,
        where.id (StringToId (evento.cloudRecoTargetId))
    );
    
    QueryMap map = await makeVuforiaRequest(Method.GET, "/targets/${reco.targetId}", "", "")
        .send()
        .then (streamResponseToJSON)
        .then (MapToQueryMap);

    //TODO: Crear clase VuforiaTargetResp
    
    if (map.result_code == "Success") 
        return new MapResp()
            ..success = true
            ..map = map;
    
    return new Resp()
        ..success = false
        ..error = map.result_code;
}

@app.Route("/public/cloudreco/:recoID", methods: const [app.GET])
@Encode()
Future<RecoTargetResp> getCloudRecoTarget(@app.Attr() MongoDb dbConn, String recoID) async
{
    AristaCloudRecoTarget reco = await dbConn.findOne
    (
        Col.recoTarget,
        AristaCloudRecoTarget,
        where.id(StringToId(recoID))
    );
    
    if (reco == null) return new Resp()
        ..success = false
        ..error = "Cloud Reco not found";
    
    return new RecoTargetResp()
        ..success = true
        ..recoTarget = reco;
}

Future<RecoTargetResp> createRecoTarget (MongoDb dbConn, String eventoID, String imageID, String targetID) async
{
    var recoTarget = new AristaCloudRecoTarget()
        ..imageId = imageID
        ..targetId = targetID
        ..id = new ObjectId().toHexString();
        
    await dbConn.insert (Col.recoTarget, recoTarget);
    
    await dbConn.update 
    (
        Col.maquina, 
        where.id (StringToId (eventoID)), 
        modify.set ('cloudRecoTargetId', recoTarget.id)
    );
    
    return new RecoTargetResp()
        ..success = true
        ..recoTarget = (new AristaCloudRecoTarget()
            ..id = recoTarget.id
            ..imageId = imageID
            ..targetId = targetID);
}

createSignature (String verb, String path, String body, String contentType, String date) 
{
      var hash = md5hash (body);
      
      print (hash);
      
      var stringToSign = '$verb\n$hash\n$contentType\n$date\n$path';
      
      print(stringToSign);

      var server_secret_key = "a26b48430ac02696539b02957f0830572eaa4c6a";
      var signature = base64_HMAC_SHA1(server_secret_key, stringToSign);

    return signature;
}

String md5hash (String body)
{
    var md5 = new crypto.MD5()
        ..add(conv.UTF8.encode (body));
    
    return crypto.CryptoUtils.bytesToHex (md5.close());
}

String base64_HMAC_SHA1 (String hexKey, String stringToSign)
{
    
    var hmac = new crypto.HMAC(new crypto.SHA1(), conv.UTF8.encode (hexKey))
        ..add(conv.UTF8.encode (stringToSign));
    
    return crypto.CryptoUtils.bytesToBase64(hmac.close());
}

http.Request makeVuforiaRequest (String verb, String path, String body, String contentType)
{
    String date = HttpDate.format(new DateTime.now());
    String accessKey = "8524c879ec19a80b912f989c33091af8ddd7ea8c";
   
    String signature = createSignature (verb, path, body, contentType, date);
    
    Map<String,String> headers = 
    {
        "Authorization" : "VWS ${accessKey}:${signature}",
        "Content-Type" : contentType,
        "Date" : date
    };
    
    var req = new http.Request (verb, new Uri.https("vws.vuforia.com", path))
        ..headers.addAll(headers);
    
    print ("Body length ${body.length}");
    
    if (body != null && body.length > 0)
        req.body = body;
    
    return req;
}


