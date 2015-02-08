part of arista;

class TextureGUI
{
    @Field() String path = '';
    
    @Field() bool web = true;
    
    @Field() String get urlTextura => path != null && path != "" ?
                                      (web ? localHost + path : path)
                                      : "";

    @Field() String texto = '';

    @Field() String get type__ => "TextureGUIJS, Assembly-CSharp";

    @Id() String id;
}