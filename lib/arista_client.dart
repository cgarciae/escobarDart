library arista_client;

import 'dart:async';
import 'dart:convert';
import 'package:escobardart/arista.dart';
import 'package:redstone_mapper/mapper.dart';
import 'package:angular/angular.dart';
import 'dart:html' as dom;
import 'package:redstone/query_map.dart';
import 'package:fp/fp.dart';

part 'components/evento/evento.dart';
part 'components/vista/vista.dart';
part 'components/login/login.dart';
part 'components/login/nuevo_usuario.dart';
part 'components/home/home.dart';
part 'routing/router.dart';
part 'components/admin/admin.dart';
part 'components/admin/model.dart';

dom.Storage get storage => dom.window.localStorage;

class ReqParam
{
    String field;
    String value;
    
    ReqParam (this.field, this.value);
    
    String get formula => field + '=' + value;
}

String reduceParams (List<ReqParam> params) =>  params.fold('?', (String acum, ReqParam elem) => (acum == '?' ? acum : acum + '&') + elem.formula);

Future<dom.HttpRequest> makeRequest (String method, String path, {dynamic data, Map headers})
{
    if (data == null)
    {
        if (headers == null)
        {
            return dom.HttpRequest.request
            (
                path,
                method: method
            );
        }
        else
        {
            return dom.HttpRequest.request
            (
                path,
                method: method,
                requestHeaders: headers
            );
        }
    }
    else
    {
        if (headers == null)
        {
            return dom.HttpRequest.request
            (
                path,
                method: method,
                sendData: data
            );
        }
        else
        {
            return dom.HttpRequest.request
            (
                path,
                method: method,
                requestHeaders: headers,
                sendData: data
            );
        }
    } 
}

Future<String> requestString (String method, String path, {dynamic data, Map headers})
{
    return makeRequest (method, path, data: data, headers: headers) 
    .then (getField (#responseText));
}

Future<dynamic> requestDecoded (Type type, String method, String path, {dynamic data, Map headers})
{
    return requestString (method, path, data: data, headers: headers)   
    .then (decodeTo (type));
}

Future<QueryMap> requestQueryMap (String method, String path, {dynamic data, Map headers})
{
    return requestString (method, path, data: data, headers: headers)
    .then (JSON.decode)
    .then (MapToQueryMap);
}

Future<dynamic> formRequestDecoded (Type type, String method, String path, dom.FormElement form, {Map headers})
{
    return requestDecoded(type, method, path, data: new dom.FormData(form), headers: headers);
}

Future<QueryMap> formRequestQueryMap (Type type, String method, String path, dom.FormElement form, {Map headers})
{
    return requestQueryMap(method, path, data: new dom.FormData(form), headers: headers);
}

Map addJSONContentType (Map headers)
{
    var contentType = {'Content-Type' : ContType.applicationJson};
        
    if (headers != null)
        headers.addAll (contentType);
    else
        headers = contentType;
    
    return headers;
}

Future<dynamic> jsonRequestDecoded (Type type, String method, String path, Object obj, {Map headers})
{   
    return requestDecoded
    (
        type, 
        method, 
        path, 
        data: encodeJson(obj), 
        headers: addJSONContentType(headers)
    );
}

Future<QueryMap> jsonRequestQueryMap (Type type, String method, String path, Object obj, {Map headers})
{
    return requestQueryMap
    (
        method, 
        path, 
        data: encodeJson(obj), 
        headers: addJSONContentType(headers)
    );
}

Future<Resp> saveInCollection(String collection, Object obj){
    return jsonRequestDecoded(Resp, Method.PUT, "private/$collection", obj);
}

Future<Resp> deleteFromCollection(String collection, String id){
    return requestDecoded(Resp, Method.DELETE, "private/$collection/$id");
}

Future<IdResp> newFromCollection (String collection)
{
    return requestDecoded (IdResp, Method.POST, "private/$collection");
}

Future<dynamic> getFromCollection (Type tipo, String collection, String id)
{
    return requestDecoded (tipo, Method.GET, "private/$collection/$id");
}

Function doIfSuccess ([dynamic f (dynamic)])
{
    return (dynamic resp)
    {
        if (resp.success)
        {
            if (f != null)
                return f (resp);
        }
        else
        {
            print (resp.error);
            return resp;
        }
    };
}

ifRespSuccess (Resp resp, Function f)
{
    if (resp.success)
    {
        if (f != null)
            return f (resp);
    }
    else
    {
        print (resp.error);
        return resp;
    }
}

Future<Resp> pushIDtoList (String collection, String objID, String fieldName, String referenceID)
{
    return requestDecoded(Resp, Method.GET,'/private/push/$collection/$objID/$fieldName/$referenceID');
}

Future<Resp> pullIDfromList (String collection, String objID, String fieldName, String referenceID)
{
    return requestDecoded(Resp, Method.GET,'/private/pull/$collection/$objID/$fieldName/$referenceID');
}

dom.FormElement getFormElement (dom.MouseEvent event) => (event.target as dom.ButtonElement).parent as dom.FormElement;

loginUser (Router router, UserAdminResp resp)
{
    storage['logged'] = resp.user.id;
    storage['admin'] = resp.user.admin.toString();
    router.go ('home', {});
}

@Injectable()
class MainController 
{
    Router router;
    
    static MainController i;
    
    MainController (this.router)
    {
        i = this;
    }
    
    logout () async
    {
        Resp resp = await requestDecoded(Resp, Method.GET,'user/logout');
        
        if (resp.success)
        {
            router.go('login', {});
        }
        else
        {
            print("Logout Failed");
        }
    }
            
    bool get isLoggedIn => loggedIn;
    
}

bool get loggedIn => storage['logged'] == true.toString();
bool get loggedAdmin => storage['admin'] == true.toString();
