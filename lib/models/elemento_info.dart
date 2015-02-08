part of arista;

class ElementoInfo
{
    @Field() String type__;
    
    //TituloInfoJS
    @Field() String titulo;
    
    //ImagenInfoJS
    @Field() String path;
    @Field() String get  url =>  path != null && path != '' ? localHost + path : '';
    
    
    //InfoTextoJS
    //titulo
    @Field() String descripcion;
}