part of arista_client;

@Component
(
    selector : "nuevo-usuario",
    templateUrl: 'components/login/nuevo_usuario.html',
    useShadowDom: false
)
class NuevoUsuarioVista
{
    UserComplete user = new UserComplete();
    String password2 = "";
    
    Router router;
    
    NuevoUsuarioVista(this.router);
    
    String get passwordStatus
    {
        return user.password == '' || password2 == '' ?     '' :
               user.password != password2 ?                 'Las contraseñas no coinciden' : 
                                                            'OK';           
    }
    
    bool get registrable
    {
        return user.nombre != '' && user.apellido != '' && user.email != '' && passwordStatus == 'OK';
    }
    
    registrar() async
    {
        if (registrable)
        {
            UserAdminResp resp = await jsonRequestDecoded
            (
                UserAdminResp,
                Method.POST, 
                'user', 
                user
            );
            
            if (resp.success)
            {
                loginUser(router, resp);
            }
        }
        else
        {
            print('Campos Incompletos');
        }
    }
}