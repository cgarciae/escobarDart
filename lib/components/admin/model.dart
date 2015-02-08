part of arista_client;

@Component
(
    selector : 'model',
    templateUrl: 'components/admin/model.html',
    useShadowDom: false
)
class ModelVista{
    
    List<ModelAdminInfo> infoList = [ ];
    Router router;
    
    ModelVista(this.router)
    {
        setModels();
    }
    
    setModels() async
    {
        ObjetoUnitySendListResp resp = await requestDecoded
        (
            ObjetoUnitySendListResp,
            Method.GET,
            'private/objetounity/pending'
        );
        
        if(! resp.success)
        {
            return print(resp.error);
        }
        
        infoList.clear();
        
        for( ObjetoUnitySend obj in resp.objs )
        {
            ModelAdminInfo info = new ModelAdminInfo();
            info.model = obj;
            
            if (! notNullOrEmpty(obj.owner))
            {
                print("Owner undefined");
                continue;
            }
            
            UserResp userResp = await requestDecoded
            (
                UserResp,
                Method.GET,
                'user/${obj.owner}'
            );
            
            if(! userResp.success)
            {
                print(userResp.error);
                continue;
            }
            
            info.user = userResp.user;
            infoList.add(info);
        }
        
    }
    
    uploadModel(ModelAdminInfo info, String system, dom.MouseEvent event) async
    {
        print ("Uploading to $system");
        
        dom.FormElement form = getFormElement (event);
        
        ObjetoUnitySendResp resp = await formRequestDecoded
        (   
            ObjetoUnitySendResp,
            Method.PUT,
            'private/objetounity/${info.model.id}/modelfile/${system}',
            form
        );
        
        if(! resp.success)
            return print (resp.error);
        
        
        info.model = resp.obj;
        info.success = resp.success;
    }
    
    publish (ModelAdminInfo info) async
    {
        
        Resp resp = await requestDecoded
        (
            Resp,
            Method.GET,
            'private/objetounity/${info.model.id}/publish'
        );
        
        if (resp.success)
            setModels();
        else
            print (resp.error);
    }
}

class ModelAdminInfo{
    ObjetoUnitySend model;
    User user;
    bool success = false; 
}