part of arista_client;

@Component
(
    selector : 'admin',
    templateUrl: 'components/admin/admin.html',
    useShadowDom: false
)
class AdminVista{
    
    Router router;
    AdminVista(this.router){
        
    }
    
    goModel ()
        {
            router.go('adminModel',{});
        }
    
}