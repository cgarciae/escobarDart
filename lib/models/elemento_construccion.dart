part of arista;


class ElementoConstruccion
{
    @Field() String get type__ => "ElementoConstruccionJS, Assembly-CSharp";
    @Field() String nombre = "";
    @Field() String titulo = "";
    @Field() String path = '';
    @Field() String get  urlImagen =>  path != null && path != '' ? localHost + path : '';
    @Field() String texto = "";
    @Field() int id;

}
